"""
map_rosqual_off_categories.py

Maps rosqual (RSKRF) category names to OpenFoodFacts categories
using embeddings + cosine similarity + LLM fallback.

Input:  kuper_category_mapping.json (163 rosqual category names)
        categories.txt (8978 OFF categories with en/ru synonyms)
Output: rosqual_off_category_mapping.json

Usage:
    python staging/map_rosqual_off_categories.py
"""

import json
import logging
import os
import re
import time
from typing import Optional

import numpy as np
from openai import OpenAI
from pydantic import BaseModel

from config import OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

EMBED_BATCH_SIZE = 2000
EMBED_MODEL = "text-embedding-3-small"
SIMILARITY_THRESHOLD = 0.65
LLM_THRESHOLD = 0.40
LLM_CANDIDATES = 15
LLM_BATCH_SIZE = 20

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CATEGORIES_TXT = os.path.join(PROJECT_DIR, "categories.txt")
KUPER_MAPPING_FILE = os.path.join(PROJECT_DIR, "kuper_category_mapping.json")
OUTPUT_FILE = os.path.join(PROJECT_DIR, "rosqual_off_category_mapping.json")
EMBEDDINGS_CACHE = os.path.join(SCRIPT_DIR, ".off_category_embeddings.npz")


# ── Parse categories.txt ─────────────────────────────────────────────────────

def parse_categories_txt(filepath: str) -> dict[str, dict]:
    """Parse OFF categories.txt → {canonical_id: {en: [...], ru: [...]}}"""
    entries: dict[str, dict] = {}

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    block_lines: list[str] = []

    def process_block(block: list[str]):
        en_names: list[str] = []
        ru_names: list[str] = []

        for bline in block:
            bline = bline.rstrip("\n")
            if bline.startswith("#") or bline.startswith("< "):
                continue
            if re.match(r"^[a-z][a-z0-9_]*:", bline) and not re.match(
                r"^[a-z]{2}(_[a-z]{2})?: ", bline
            ):
                continue
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
                entries[canonical]["en"] = list(
                    set(entries[canonical]["en"]) | set(en_names)
                )
                entries[canonical]["ru"] = list(
                    set(entries[canonical]["ru"]) | set(ru_names)
                )
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


# ── Embeddings ────────────────────────────────────────────────────────────────

def get_embeddings(client: OpenAI, texts: list[str]) -> np.ndarray:
    all_embeddings = []
    for i in range(0, len(texts), EMBED_BATCH_SIZE):
        batch = texts[i:i + EMBED_BATCH_SIZE]
        log.info("  Embedding batch %d-%d / %d", i + 1, i + len(batch), len(texts))
        response = client.embeddings.create(model=EMBED_MODEL, input=batch)
        batch_emb = [item.embedding for item in response.data]
        all_embeddings.extend(batch_emb)
    return np.array(all_embeddings, dtype=np.float32)


# ── LLM fallback ─────────────────────────────────────────────────────────────

class CategoryMapping(BaseModel):
    name: str
    category_id: Optional[str] = None


class MappingResponse(BaseModel):
    mappings: list[CategoryMapping]


LLM_SYSTEM_PROMPT = """\
Для каждой категории продуктов дан список кандидатов из таксономии OpenFoodFacts (id + название).
Выбери НАИБОЛЕЕ ПОДХОДЯЩИЙ.

Правила:
- Выбирай категорию максимально точно соответствующую по смыслу.
- Если ничего не подходит → category_id = null.
- Используй ТОЛЬКО id из кандидатов.
"""


def llm_fallback(
    client: OpenAI,
    items: list[dict],
) -> list[CategoryMapping]:
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
                max_tokens=4096,
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
            time.sleep(wait)

    return []


# ── Main ──────────────────────────────────────────────────────────────────────

def run():
    # 1. Parse OFF categories
    log.info("Parsing %s", CATEGORIES_TXT)
    categories = parse_categories_txt(CATEGORIES_TXT)
    log.info("Parsed %d OFF categories", len(categories))

    with_ru = sum(1 for e in categories.values() if e.get("ru"))
    log.info("  With Russian: %d", with_ru)

    # 2. Load rosqual category names
    with open(KUPER_MAPPING_FILE, "r", encoding="utf-8") as f:
        raw = json.load(f)

    rosqual_names = list(raw.get("rskrf_to_kuper", raw).keys())
    # Clean trailing spaces
    rosqual_names = [n.strip() for n in rosqual_names]
    rosqual_names = list(dict.fromkeys(rosqual_names))  # dedupe preserving order
    log.info("Rosqual category names: %d", len(rosqual_names))

    # 3. Build per-synonym embeddings for OFF categories
    syn_texts: list[str] = []
    syn_tids: list[str] = []

    for tid, entry in categories.items():
        ru = entry.get("ru", [])
        en = entry.get("en", [])
        synonyms = ru if ru else en
        for syn in synonyms:
            s = syn.strip()
            if s:
                syn_texts.append(s)
                syn_tids.append(tid)

    log.info("OFF synonym embeddings: %d texts from %d categories",
             len(syn_texts), len(categories))

    client = OpenAI(api_key=OPENAI_API_KEY)

    # Try loading cached embeddings
    off_embeddings = None
    if os.path.exists(EMBEDDINGS_CACHE):
        log.info("Loading cached OFF category embeddings...")
        data = np.load(EMBEDDINGS_CACHE, allow_pickle=True)
        cached_texts = list(data["texts"])
        if cached_texts == syn_texts:
            off_embeddings = data["embeddings"]
            log.info("  Cache valid: %d synonyms", len(syn_texts))
        else:
            log.info("  Cache stale (%d vs %d), rebuilding",
                     len(cached_texts), len(syn_texts))

    if off_embeddings is None:
        log.info("Building OFF category embeddings...")
        off_embeddings = get_embeddings(client, syn_texts)
        np.savez(
            EMBEDDINGS_CACHE,
            texts=np.array(syn_texts, dtype=object),
            embeddings=off_embeddings,
        )
        log.info("  Cached to %s", EMBEDDINGS_CACHE)

    # 4. Embed rosqual names
    log.info("Embedding %d rosqual names...", len(rosqual_names))
    rq_embeddings = get_embeddings(client, rosqual_names)

    # 5. Cosine similarity
    log.info("Computing cosine similarities...")
    q_norm = rq_embeddings / np.linalg.norm(rq_embeddings, axis=1, keepdims=True)
    t_norm = off_embeddings / np.linalg.norm(off_embeddings, axis=1, keepdims=True)
    sim = q_norm @ t_norm.T

    done: dict[str, Optional[str]] = {}
    llm_items: list[dict] = []
    llm_names: list[str] = []
    matched = 0
    no_match = 0

    for idx, name in enumerate(rosqual_names):
        best_syn_idx = int(np.argmax(sim[idx]))
        best_score = float(sim[idx][best_syn_idx])
        best_tid = syn_tids[best_syn_idx]
        best_syn_text = syn_texts[best_syn_idx]

        if best_score >= SIMILARITY_THRESHOLD:
            done[name] = best_tid
            matched += 1
            log.info("  %.3f  %s → %s (%s)", best_score, name, best_tid, best_syn_text)
        elif best_score >= LLM_THRESHOLD:
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
            llm_items.append({"name": name, "candidates": candidates})
            llm_names.append(name)
            log.info("  %.3f  %s → LLM (%d candidates, best: %s — %s)",
                     best_score, name, len(candidates), best_tid, best_syn_text)
        else:
            done[name] = None
            no_match += 1
            log.info("  %.3f  %s → null (best: %s — %s)",
                     best_score, name, best_tid, best_syn_text)

    log.info("Embedding match: %d auto, %d → LLM, %d null",
             matched, len(llm_items), no_match)

    # 6. LLM fallback
    if llm_items:
        log.info("Running LLM fallback for %d categories...", len(llm_items))
        llm_matched = 0
        llm_null = 0

        for batch_start in range(0, len(llm_items), LLM_BATCH_SIZE):
            batch = llm_items[batch_start:batch_start + LLM_BATCH_SIZE]
            batch_names = llm_names[batch_start:batch_start + LLM_BATCH_SIZE]
            log.info("  LLM batch %d-%d / %d",
                     batch_start + 1, batch_start + len(batch), len(llm_items))

            mappings = llm_fallback(client, batch)
            mapping_by_name = {m.name: m.category_id for m in mappings}

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

    # 7. Save mapping
    total_matched = sum(1 for v in done.values() if v is not None)
    total_null = sum(1 for v in done.values() if v is None)
    log.info("TOTAL: %d matched, %d null, %d total",
             total_matched, total_null, len(done))

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(done, f, ensure_ascii=False, indent=2)

    log.info("Saved to %s", OUTPUT_FILE)


if __name__ == "__main__":
    run()
