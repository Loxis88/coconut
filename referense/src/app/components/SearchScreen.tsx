import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { MOCK_PRODUCTS, getScoreColor, getScoreLabel } from "./data";
import type { Product, Screen } from "./data";

const CATEGORIES = [
  { label: "Молочные", icon: "🥛", key: "Молочные продукты" },
  { label: "Сладости", icon: "🍫", key: "Сладости" },
  { label: "Снеки", icon: "🥨", key: "Снеки" },
  { label: "Напитки", icon: "🥤", key: "Напитки" },
  { label: "Крупы", icon: "🌾", key: "Крупы" },
  { label: "Мясо", icon: "🥩", key: "Мясо" },
];

type ScoreFilter = "all" | "good" | "ok" | "bad";

const SCORE_FILTERS: { key: ScoreFilter; label: string; color: string }[] = [
  { key: "all", label: "Все", color: "#5E6859" },
  { key: "good", label: "Хорошие", color: "#1E6B28" },
  { key: "ok", label: "Средние", color: "#B87D28" },
  { key: "bad", label: "Плохие", color: "#C03B32" },
];

function scoreFilter(score: number, f: ScoreFilter) {
  if (f === "good") return score >= 70;
  if (f === "ok") return score >= 40 && score < 70;
  if (f === "bad") return score < 40;
  return true;
}

export function SearchScreen({ onNavigate }: { onNavigate: (s: Screen, p?: Product) => void }) {
  const [q, setQ] = useState("");
  const [focused, setFocused] = useState(false);
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null);
  const [scoreF, setScoreF] = useState<ScoreFilter>("all");
  const inputRef = useRef<HTMLInputElement>(null);

  const trimmed = q.trim();
  const isSearching = trimmed.length > 0 || categoryFilter !== null;

  const results = MOCK_PRODUCTS.filter(p => {
    const matchText = trimmed.length === 0 ||
      p.name.toLowerCase().includes(trimmed.toLowerCase()) ||
      p.brand.toLowerCase().includes(trimmed.toLowerCase());
    const matchCat = categoryFilter === null || p.category === categoryFilter;
    const matchScore = scoreFilter(p.score, scoreF);
    return matchText && matchCat && matchScore;
  });

  // top picks — highest score
  const topPicks = [...MOCK_PRODUCTS].sort((a, b) => b.score - a.score).slice(0, 3);

  const clear = () => { setQ(""); setCategoryFilter(null); setScoreF("all"); };

  return (
    <div className="flex flex-col h-full" style={{ background: "#E8E3D6" }}>

      {/* ── Search bar ── */}
      <div className="px-4 flex-shrink-0" style={{ paddingTop: 56, paddingBottom: 12 }}>
        <div
          className="flex items-center gap-3 px-4 rounded-2xl"
          style={{
            background: focused ? "#F4F0E6" : "rgba(12,26,9,0.07)",
            border: `1.5px solid ${focused ? "rgba(21,57,24,0.22)" : "transparent"}`,
            boxShadow: focused ? "0 4px 16px rgba(21,57,24,0.08)" : "none",
            transition: "all 0.2s",
          }}
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{ flexShrink: 0, opacity: 0.5 }}>
            <circle cx="7" cy="7" r="5" stroke="#0C1A09" strokeWidth="1.6" />
            <path d="M11 11l3.5 3.5" stroke="#0C1A09" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
          <input
            ref={inputRef}
            value={q}
            onChange={e => setQ(e.target.value)}
            onFocus={() => setFocused(true)}
            onBlur={() => setTimeout(() => setFocused(false), 80)}
            placeholder="Продукт, бренд или категория…"
            className="flex-1 py-4 outline-none bg-transparent"
            style={{ fontFamily: "var(--font-body)", fontSize: "15px", color: "#0C1A09" }}
          />
          <AnimatePresence>
            {(q.length > 0 || categoryFilter) && (
              <motion.button
                initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.8 }}
                onClick={clear} style={{ flexShrink: 0 }}
              >
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                  <circle cx="9" cy="9" r="7" fill="rgba(12,26,9,0.1)" />
                  <path d="M6 6l6 6M12 6l-6 6" stroke="#5E6859" strokeWidth="1.5" strokeLinecap="round" />
                </svg>
              </motion.button>
            )}
          </AnimatePresence>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        <AnimatePresence mode="wait">

          {/* ── EMPTY STATE ── */}
          {!isSearching && (
            <motion.div key="empty"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.18 }}
            >
              {/* Categories */}
              <div className="px-4 mb-5">
                <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: 10 }}>
                  Категории
                </p>
                <div className="grid grid-cols-3 gap-2">
                  {CATEGORIES.map(cat => (
                    <button
                      key={cat.key}
                      onClick={() => setCategoryFilter(cat.key)}
                      className="rounded-2xl p-3 text-left"
                      style={{ background: "#F4F0E6", boxShadow: "0 1px 4px rgba(0,0,0,0.05)" }}
                    >
                      <span style={{ fontSize: 22, lineHeight: 1, display: "block", marginBottom: 6 }}>{cat.icon}</span>
                      <span style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "13px", color: "#0C1A09" }}>{cat.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Top picks */}
              <div className="px-4 pb-8">
                <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: 10 }}>
                  Топ оценок
                </p>
                <div className="flex flex-col gap-2">
                  {topPicks.map((p, i) => (
                    <motion.button
                      key={p.id}
                      initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
                      onClick={() => onNavigate("product", p)}
                      className="flex items-center gap-3 p-3 rounded-2xl text-left"
                      style={{ background: "#F4F0E6", boxShadow: "0 1px 4px rgba(0,0,0,0.05)", borderLeft: `3px solid ${getScoreColor(p.score)}` }}
                    >
                      <div className="w-10 h-10 rounded-xl overflow-hidden flex-shrink-0" style={{ background: "#DDD8CB" }}>
                        <img src={p.image} alt={p.name} className="w-full h-full object-cover" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="truncate" style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "13px", color: "#0C1A09" }}>{p.name}</p>
                        <p style={{ fontFamily: "var(--font-body)", fontSize: "11px", color: "#5E6859" }}>{p.brand} · {p.calories} ккал</p>
                      </div>
                      <div className="flex-shrink-0 text-right">
                        <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "20px", color: getScoreColor(p.score), lineHeight: 1 }}>{p.score}</span>
                        <p style={{ fontFamily: "var(--font-mono)", fontSize: "8px", color: getScoreColor(p.score) }}>{getScoreLabel(p.score)}</p>
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>
            </motion.div>
          )}

          {/* ── RESULTS ── */}
          {isSearching && (
            <motion.div key="results"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.18 }}
              className="px-4 pb-8"
            >
              {/* Active category chip + score filter */}
              <div className="flex items-center gap-2 mb-3 flex-wrap">
                {categoryFilter && (
                  <button
                    onClick={() => setCategoryFilter(null)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl"
                    style={{ background: "#153918", fontFamily: "var(--font-body)", fontSize: "12px", fontWeight: 600, color: "white" }}
                  >
                    {CATEGORIES.find(c => c.key === categoryFilter)?.icon} {CATEGORIES.find(c => c.key === categoryFilter)?.label}
                    <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                      <path d="M2 2l6 6M8 2l-6 6" stroke="white" strokeWidth="1.5" strokeLinecap="round" />
                    </svg>
                  </button>
                )}
                <div className="flex gap-1.5 flex-wrap">
                  {SCORE_FILTERS.map(f => (
                    <button
                      key={f.key}
                      onClick={() => setScoreF(f.key)}
                      className="px-3 py-1.5 rounded-xl"
                      style={{
                        background: scoreF === f.key ? `${f.color}18` : "rgba(12,26,9,0.06)",
                        border: `1px solid ${scoreF === f.key ? `${f.color}40` : "transparent"}`,
                        fontFamily: "var(--font-body)",
                        fontSize: "12px",
                        fontWeight: scoreF === f.key ? 600 : 400,
                        color: scoreF === f.key ? f.color : "#5E6859",
                        transition: "all 0.15s",
                      }}
                    >
                      {f.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Count */}
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", letterSpacing: "0.04em", marginBottom: 10 }}>
                {results.length > 0 ? `${results.length} ${results.length === 1 ? "продукт" : results.length < 5 ? "продукта" : "продуктов"}` : "Ничего не найдено"}
              </p>

              {results.length > 0 ? (
                <div className="flex flex-col gap-2">
                  {results.map((p, i) => (
                    <motion.button
                      key={p.id}
                      initial={{ opacity: 0, y: 6 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: Math.min(i * 0.04, 0.2) }}
                      onClick={() => onNavigate("product", p)}
                      className="w-full flex items-center gap-3 p-3 rounded-2xl text-left"
                      style={{ background: "#F4F0E6", boxShadow: "0 1px 4px rgba(0,0,0,0.05)", borderLeft: `3px solid ${getScoreColor(p.score)}` }}
                    >
                      <div className="w-12 h-12 rounded-xl overflow-hidden flex-shrink-0" style={{ background: "#DDD8CB" }}>
                        <img src={p.image} alt={p.name} className="w-full h-full object-cover" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="truncate" style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "14px", color: "#0C1A09" }}>{p.name}</p>
                        <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{p.brand}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486" }}>{p.calories} ккал</span>
                          <span style={{ width: 2, height: 2, borderRadius: "50%", background: "#C4BFB4", display: "inline-block" }} />
                          <span style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486" }}>{p.category}</span>
                        </div>
                      </div>
                      <div className="flex-shrink-0 text-right">
                        <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "22px", color: getScoreColor(p.score), lineHeight: 1 }}>{p.score}</span>
                        <p style={{ fontFamily: "var(--font-mono)", fontSize: "8px", color: getScoreColor(p.score), marginTop: 1 }}>{getScoreLabel(p.score)}</p>
                      </div>
                    </motion.button>
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center py-16 gap-3">
                  <div className="w-14 h-14 rounded-2xl flex items-center justify-center" style={{ background: "rgba(12,26,9,0.06)" }}>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                      <circle cx="10" cy="10" r="7" stroke="#8A9486" strokeWidth="1.8" />
                      <path d="M16 16l5 5" stroke="#8A9486" strokeWidth="1.8" strokeLinecap="round" />
                    </svg>
                  </div>
                  <p style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "15px", color: "#0C1A09" }}>Ничего не найдено</p>
                  <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#5E6859", textAlign: "center", maxWidth: 200 }}>
                    Попробуйте другой запрос или сбросьте фильтры
                  </p>
                  <button onClick={clear} className="mt-1 px-4 py-2 rounded-xl"
                    style={{ background: "rgba(21,57,24,0.1)", fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "#153918" }}>
                    Сбросить
                  </button>
                </div>
              )}
            </motion.div>
          )}

        </AnimatePresence>
      </div>
    </div>
  );
}
