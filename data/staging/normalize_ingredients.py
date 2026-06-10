"""
normalize_ingredients.py

Maps ingredient names from staging.raw_product_ingredients
to Open Food Data taxonomy using embeddings.

Strategy:
  1. Parse ingredients.txt + additives.txt → build taxonomy with Russian synonyms.
  2. Exact match by all Russian synonyms (no API calls).
  3. For unmatched: embed taxonomy (with Russian synonyms) + ingredients,
     find nearest by cosine similarity above threshold.

Writes results to product_catalog.ingredient_alias (alias → canonical_name).

Usage:
    python staging/normalize_ingredients.py
"""

import os
import json
import re
import logging
import numpy as np
from typing import Optional

import psycopg2
from psycopg2.extras import execute_values
from pydantic import BaseModel
from openai import OpenAI

from config import DB_CONFIG, OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

EMBED_BATCH_SIZE = 2000
EMBED_MODEL = "text-embedding-3-small"
SIMILARITY_THRESHOLD = 0.65
LLM_THRESHOLD = 0.45        # below this, skip LLM (too far)
LLM_CANDIDATES = 10
LLM_BATCH_SIZE = 20

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
INGREDIENTS_TXT = os.path.join(PROJECT_DIR, "ingredients.txt")
ADDITIVES_TXT = os.path.join(PROJECT_DIR, "additives.txt")
TAXONOMY_EMBEDDINGS_FILE = os.path.join(SCRIPT_DIR, ".taxonomy_embeddings_v2.npz")


# ── Parse OpenFoodFacts taxonomy .txt files ─────────────────────────────────

def parse_taxonomy_txt(filepath: str) -> dict[str, dict]:
    """
    Parse OpenFoodFacts taxonomy .txt file.

    Format:
      < en:parent           (optional parent refs, before en: line)
      en: canonical, syn1, syn2
      ru: syn_ru1, syn_ru2
      ...properties...
      (empty line = end of entry)

    Returns: {canonical_id: {en: [...], ru: [...]}}
    """
    entries: dict[str, dict] = {}

    # Read all lines, split into blocks by empty lines
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    block_lines: list[str] = []

    def process_block(block: list[str]):
        """Process a block of lines as one taxonomy entry."""
        en_names: list[str] = []
        ru_names: list[str] = []

        for bline in block:
            bline = bline.rstrip("\n")
            if bline.startswith("#") or bline.startswith("< "):
                continue
            # Property lines: word_word:en: or single_word: with colon in value
            # Skip lines like "additives_classes:en:", "e_number:en:", "vegan:en:"
            if re.match(r"^[a-z][a-z0-9_]*:", bline) and not re.match(r"^[a-z]{2}(_[a-z]{2})?: ", bline):
                continue
            # Language line
            m = re.match(r"^([a-z]{2}(?:_[a-z]{2})?): (.+)$", bline)
            if m:
                lang = m.group(1)
                values = [v.strip() for v in m.group(2).split(",") if v.strip()]
                if lang == "en":
                    en_names.extend(values)
                elif lang == "ru":
                    ru_names.extend(values)

        if en_names:
            canonical = "en:" + en_names[0].lower().replace(" ", "-")
            if canonical in entries:
                # Merge
                entries[canonical]["en"] = list(set(entries[canonical]["en"]) | set(en_names))
                entries[canonical]["ru"] = list(set(entries[canonical]["ru"]) | set(ru_names))
            else:
                entries[canonical] = {"en": en_names, "ru": ru_names}

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if block_lines:
                process_block(block_lines)
                block_lines = []
        else:
            block_lines.append(line)

    if block_lines:
        process_block(block_lines)

    return entries


def merge_taxonomies(*taxonomies: dict[str, dict]) -> dict[str, dict]:
    """Merge multiple parsed taxonomies, combining synonyms."""
    merged: dict[str, dict] = {}
    for tax in taxonomies:
        for tid, entry in tax.items():
            if tid in merged:
                # Merge synonyms
                existing_ru = set(merged[tid].get("ru", []))
                existing_en = set(merged[tid].get("en", []))
                existing_ru.update(entry.get("ru", []))
                existing_en.update(entry.get("en", []))
                merged[tid]["ru"] = list(existing_ru)
                merged[tid]["en"] = list(existing_en)
            else:
                merged[tid] = {
                    "en": list(entry.get("en", [])),
                    "ru": list(entry.get("ru", [])),
                }
    return merged


# ── Pydantic + LLM fallback ─────────────────────────────────────────────────

class IngredientMapping(BaseModel):
    name: str
    taxonomy_id: Optional[str] = None


class MappingResponse(BaseModel):
    mappings: list[IngredientMapping]


LLM_SYSTEM_PROMPT = """\
Для каждого ингредиента дан список кандидатов из таксономии (id + название).
Выбери НАИБОЛЕЕ ПОДХОДЯЩИЙ.

Правила:
- "ароматизатор X" = ароматизатор, НЕ сам X. Ищи *-flavouring.
- "функция + вещество" (загуститель пектин) → вещество (en:e440), не функция.
- Если ничего не подходит → taxonomy_id = null.
- Используй ТОЛЬКО id из кандидатов.
"""


def llm_fallback(
    client: OpenAI,
    items: list[dict],
) -> list[IngredientMapping]:
    """LLM picks best match from embedding candidates."""
    user_content = json.dumps({"items": items}, ensure_ascii=False)

    for attempt in range(3):
        try:
            completion = client.beta.chat.completions.parse(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": LLM_SYSTEM_PROMPT},
                    {"role": "user", "content": user_content},
                ],
                response_format=MappingResponse,
                temperature=0.0,
                max_tokens=8192,
            )
            usage = completion.usage
            log.info(
                "  LLM tokens: %d prompt + %d completion = %d total",
                usage.prompt_tokens, usage.completion_tokens, usage.total_tokens,
            )
            parsed = completion.choices[0].message.parsed
            if parsed is None:
                continue
            return parsed.mappings
        except Exception as e:
            wait = 2 ** attempt
            log.warning("  LLM attempt %d failed: %s — retry in %ds", attempt + 1, e, wait)
            import time
            time.sleep(wait)

    return []


# ── Embeddings ──────────────────────────────────────────────────────────────

def get_embeddings(client: OpenAI, texts: list[str]) -> np.ndarray:
    all_embeddings = []
    for i in range(0, len(texts), EMBED_BATCH_SIZE):
        batch = texts[i:i + EMBED_BATCH_SIZE]
        log.info("  Embedding batch %d-%d / %d", i + 1, i + len(batch), len(texts))
        response = client.embeddings.create(model=EMBED_MODEL, input=batch)
        batch_emb = [item.embedding for item in response.data]
        all_embeddings.extend(batch_emb)
    return np.array(all_embeddings, dtype=np.float32)


# ── Main ────────────────────────────────────────────────────────────────────

def run_normalization():
    # 1. Parse taxonomy files
    log.info("Parsing %s", INGREDIENTS_TXT)
    ingredients_tax = parse_taxonomy_txt(INGREDIENTS_TXT)
    log.info("  Parsed %d entries from ingredients.txt", len(ingredients_tax))

    log.info("Parsing %s", ADDITIVES_TXT)
    additives_tax = parse_taxonomy_txt(ADDITIVES_TXT)
    log.info("  Parsed %d entries from additives.txt", len(additives_tax))

    taxonomy = merge_taxonomies(ingredients_tax, additives_tax)
    log.info("Merged taxonomy: %d entries", len(taxonomy))

    # Count stats
    with_ru = sum(1 for e in taxonomy.values() if e.get("ru"))
    total_ru_synonyms = sum(len(e.get("ru", [])) for e in taxonomy.values())
    log.info("  Entries with Russian: %d, total Russian synonyms: %d", with_ru, total_ru_synonyms)

    # 2. Build exact lookup: lowercase Russian/English synonym → taxonomy_id
    exact_lookup: dict[str, str] = {}
    for tid, entry in taxonomy.items():
        for name in entry.get("ru", []):
            key = name.lower().strip()
            if key and key not in exact_lookup:
                exact_lookup[key] = tid
        for name in entry.get("en", []):
            key = name.lower().strip()
            if key and key not in exact_lookup:
                exact_lookup[key] = tid

    log.info("Exact lookup: %d synonyms", len(exact_lookup))

    # 3. Get distinct ingredient names from staging
    conn = psycopg2.connect(**DB_CONFIG)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT DISTINCT ingredient_name
            FROM staging.raw_product_ingredients
            ORDER BY ingredient_name
        """)
        all_names = [row[0] for row in cur.fetchall()]

    log.info("Distinct ingredient names in staging: %d", len(all_names))

    # 4. Exact match pass
    done: dict[str, Optional[str]] = {}
    need_embed = []

    for name in all_names:
        tid = exact_lookup.get(name.lower().strip())
        if tid:
            done[name] = tid
        else:
            need_embed.append(name)

    log.info("Exact match: %d, need embedding: %d", len(done), len(need_embed))

    if not need_embed:
        log.info("All matched exactly!")
    else:
        client = OpenAI(api_key=OPENAI_API_KEY)

        # 5. Build per-synonym embeddings
        # One embedding per Russian synonym (or English if no Russian).
        # This gives much higher cosine scores than one embedding per entry.
        syn_texts: list[str] = []   # text to embed
        syn_tids: list[str] = []    # corresponding taxonomy_id

        for tid, entry in taxonomy.items():
            ru = entry.get("ru", [])
            en = entry.get("en", [])
            # Prefer Russian synonyms (our ingredients are Russian)
            synonyms = ru if ru else en
            if not synonyms:
                continue
            for syn in synonyms:
                s = syn.strip()
                if s:
                    syn_texts.append(s)
                    syn_tids.append(tid)

        log.info("Taxonomy synonym embeddings: %d texts from %d entries",
                 len(syn_texts), len(taxonomy))

        # Try loading cached embeddings
        tax_embeddings = None
        if os.path.exists(TAXONOMY_EMBEDDINGS_FILE):
            log.info("Loading cached taxonomy embeddings...")
            data = np.load(TAXONOMY_EMBEDDINGS_FILE, allow_pickle=True)
            cached_texts = list(data["texts"])
            if cached_texts == syn_texts:
                tax_embeddings = data["embeddings"]
                log.info("  Cache valid: %d synonyms", len(syn_texts))
            else:
                log.info("  Cache stale (%d vs %d), rebuilding",
                         len(cached_texts), len(syn_texts))

        if tax_embeddings is None:
            log.info("Building taxonomy embeddings...")
            tax_embeddings = get_embeddings(client, syn_texts)
            np.savez(
                TAXONOMY_EMBEDDINGS_FILE,
                texts=np.array(syn_texts, dtype=object),
                embeddings=tax_embeddings,
            )
            log.info("  Cached to %s", TAXONOMY_EMBEDDINGS_FILE)

        # 6. Embed ingredient names
        log.info("Embedding %d ingredient names...", len(need_embed))
        ing_embeddings = get_embeddings(client, need_embed)

        # 7. Find nearest by cosine similarity
        log.info("Computing cosine similarities...")
        q_norm = ing_embeddings / np.linalg.norm(ing_embeddings, axis=1, keepdims=True)
        t_norm = tax_embeddings / np.linalg.norm(tax_embeddings, axis=1, keepdims=True)
        sim = q_norm @ t_norm.T

        matched = 0
        no_match = 0
        llm_items: list[dict] = []  # items for LLM fallback
        llm_names: list[str] = []   # corresponding ingredient names

        for idx, name in enumerate(need_embed):
            best_syn_idx = int(np.argmax(sim[idx]))
            best_score = float(sim[idx][best_syn_idx])
            best_tid = syn_tids[best_syn_idx]
            best_syn_text = syn_texts[best_syn_idx]

            if best_score >= SIMILARITY_THRESHOLD:
                done[name] = best_tid
                matched += 1
                log.info("  %.3f  %s → %s (%s)",
                         best_score, name, best_tid, best_syn_text)
            elif best_score >= LLM_THRESHOLD:
                # Collect top-K candidates for LLM
                top_indices = np.argsort(sim[idx])[::-1][:LLM_CANDIDATES]
                candidates = []
                seen_tids = set()
                for si in top_indices:
                    tid = syn_tids[si]
                    if tid not in seen_tids:
                        seen_tids.add(tid)
                        score = float(sim[idx][si])
                        label = syn_texts[si]
                        candidates.append({
                            "id": tid,
                            "name": label,
                            "score": round(score, 3),
                        })
                llm_items.append({
                    "name": name,
                    "candidates": candidates,
                })
                llm_names.append(name)
                log.info("  %.3f  %s → LLM (%d candidates, best: %s — %s)",
                         best_score, name, len(candidates), best_tid, best_syn_text)
            else:
                done[name] = None
                no_match += 1
                log.info("  %.3f  %s → null (best: %s — %s)",
                         best_score, name, best_tid, best_syn_text)

        log.info("Embedding match: %d auto, %d → LLM, %d null (thresholds=%.2f/%.2f)",
                 matched, len(llm_items), no_match, SIMILARITY_THRESHOLD, LLM_THRESHOLD)

        # 8. LLM fallback for uncertain matches
        if llm_items:
            log.info("Running LLM fallback for %d ingredients...", len(llm_items))
            llm_matched = 0
            llm_null = 0

            for batch_start in range(0, len(llm_items), LLM_BATCH_SIZE):
                batch = llm_items[batch_start:batch_start + LLM_BATCH_SIZE]
                batch_names = llm_names[batch_start:batch_start + LLM_BATCH_SIZE]
                log.info("  LLM batch %d-%d / %d",
                         batch_start + 1, batch_start + len(batch), len(llm_items))

                mappings = llm_fallback(client, batch)

                # Build lookup by name
                mapping_by_name = {m.name: m.taxonomy_id for m in mappings}

                for name in batch_names:
                    tid = mapping_by_name.get(name)
                    if tid:
                        done[name] = tid
                        llm_matched += 1
                        log.info("    LLM: %s → %s", name, tid)
                    else:
                        done[name] = None
                        llm_null += 1
                        log.info("    LLM: %s → null", name)

            log.info("LLM fallback: %d matched, %d null", llm_matched, llm_null)

    # 9. Write to DB
    total_matched = sum(1 for v in done.values() if v is not None)
    total_null = sum(1 for v in done.values() if v is None)
    log.info("TOTAL: %d matched, %d no match, %d total",
             total_matched, total_null, len(done))

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS product_catalog.ingredient_alias (
                alias TEXT PRIMARY KEY,
                canonical_name TEXT NOT NULL
            )
        """)
    conn.commit()

    alias_pairs = [(name, tid) for name, tid in done.items() if tid is not None]

    with conn.cursor() as cur:
        cur.execute("TRUNCATE product_catalog.ingredient_alias")
        if alias_pairs:
            execute_values(
                cur,
                """
                INSERT INTO product_catalog.ingredient_alias (alias, canonical_name)
                VALUES %s
                ON CONFLICT (alias) DO UPDATE SET canonical_name = EXCLUDED.canonical_name
                """,
                alias_pairs,
            )
            log.info("Inserted %d aliases", len(alias_pairs))

    conn.commit()
    conn.close()
    log.info("Done")


if __name__ == "__main__":
    run_normalization()
