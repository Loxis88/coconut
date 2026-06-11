import { useState } from "react";
import { motion } from "motion/react";
import { MOCK_PRODUCTS, getScoreColor, getScoreLabel } from "./data";
import type { Product, Screen } from "./data";

const FILTERS = [
  { id: "all", label: "Все" },
  { id: "good", label: "≥ 75" },
  { id: "mid", label: "35–74" },
  { id: "bad", label: "< 35" },
  { id: "fav", label: "Избранные" },
];

export function HistoryScreen({ onNavigate }: { onNavigate: (s: Screen, p?: Product) => void }) {
  const [filter, setFilter] = useState("all");
  const [favs, setFavs] = useState<Set<string>>(new Set(["1"]));

  const toggleFav = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setFavs((prev) => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });
  };

  const visible = MOCK_PRODUCTS.filter((p) => {
    if (filter === "good") return p.score >= 75;
    if (filter === "mid") return p.score >= 35 && p.score < 75;
    if (filter === "bad") return p.score < 35;
    if (filter === "fav") return favs.has(p.id);
    return true;
  });

  const avg = Math.round(MOCK_PRODUCTS.reduce((a, p) => a + p.score, 0) / MOCK_PRODUCTS.length);

  return (
    <div className="flex flex-col h-full" style={{ background: "#E8E3D6" }}>
      {/* Header */}
      <div className="px-5 pt-14 pb-4">
        <div className="flex items-baseline justify-between mb-5">
          <div>
            <h1 style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "26px", color: "#0C1A09", letterSpacing: "-0.025em" }}>
              История
            </h1>
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "#5E6859", marginTop: "2px" }}>
              {MOCK_PRODUCTS.length} продуктов за 30 дней
            </p>
          </div>
          {/* Avg score badge */}
          <div className="text-right">
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "36px", color: getScoreColor(avg), lineHeight: 1 }}>
              {avg}
            </div>
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "#5E6859", letterSpacing: "0.04em" }}>
              СРЕДНИЙ БАЛЛ
            </p>
          </div>
        </div>

        {/* Stat row */}
        <div className="flex gap-2 mb-4">
          {[
            { label: "Отлично", count: MOCK_PRODUCTS.filter((p) => p.score >= 75).length, color: "#1E6B28" },
            { label: "Хорошо", count: MOCK_PRODUCTS.filter((p) => p.score >= 55 && p.score < 75).length, color: "#4A9152" },
            { label: "Плохо", count: MOCK_PRODUCTS.filter((p) => p.score < 35).length, color: "#C03B32" },
            { label: "Избранные", count: favs.size, color: "#B87D28" },
          ].map((s) => (
            <div key={s.label} className="flex-1 rounded-xl p-3" style={{ background: "#F4F0E6" }}>
              <p style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "20px", color: s.color, lineHeight: 1 }}>{s.count}</p>
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "#5E6859", marginTop: "2px", letterSpacing: "0.04em" }}>{s.label}</p>
            </div>
          ))}
        </div>

        {/* Filter chips */}
        <div className="flex gap-2 overflow-x-auto pb-0.5" style={{ scrollbarWidth: "none" }}>
          {FILTERS.map((f) => (
            <button
              key={f.id}
              onClick={() => setFilter(f.id)}
              className="flex-shrink-0 px-4 py-2 rounded-xl transition-all"
              style={{
                background: filter === f.id ? "#153918" : "#F4F0E6",
                color: filter === f.id ? "white" : "#5E6859",
                fontFamily: "var(--font-body)",
                fontWeight: filter === f.id ? 600 : 400,
                fontSize: "13px",
              }}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto px-5 pb-8">
        {visible.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 gap-3">
            <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px", color: "#0C1A09" }}>Пусто</p>
            <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#5E6859" }}>Измените фильтр</p>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: "4px" }}>
              Последние 30 дней
            </p>
            {visible.map((p, i) => (
              <motion.div
                key={p.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.04 }}
                onClick={() => onNavigate("product", p)}
                className="w-full flex items-center gap-4 p-4 rounded-2xl text-left cursor-pointer active:scale-98 transition-transform"
                style={{ background: "#F4F0E6", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}
              >
                <div className="w-12 h-12 rounded-xl overflow-hidden flex-shrink-0" style={{ background: "#DDD8CB" }}>
                  <img src={p.image} alt={p.name} className="w-full h-full object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <p style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "14px", color: "#0C1A09" }} className="truncate">{p.name}</p>
                  <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{p.brand}</p>
                  <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", marginTop: "1px" }}>{p.scannedAt}</p>
                </div>
                <div className="flex items-center gap-3 flex-shrink-0">
                  <div className="text-right">
                    <p style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "24px", color: getScoreColor(p.score), lineHeight: 1 }}>
                      {p.score}
                    </p>
                    <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: getScoreColor(p.score), letterSpacing: "0.03em" }}>
                      {getScoreLabel(p.score)}
                    </p>
                  </div>
                  <button
                    onClick={(e) => toggleFav(p.id, e)}
                    className="p-1"
                  >
                    <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                      <path
                        d="M9 15.5L2 9C.8 7.8.5 6 1.1 4.5A4.2 4.2 0 015.3 2c1.5 0 2.9.7 3.7 1.9A4.7 4.7 0 019 15.5z"
                        fill={favs.has(p.id) ? "#C03B32" : "none"}
                        stroke={favs.has(p.id) ? "#C03B32" : "#B8C0B4"}
                        strokeWidth="1.5"
                      />
                      <path
                        d="M9 15.5L16 9C17.2 7.8 17.5 6 16.9 4.5A4.2 4.2 0 0012.7 2c-1.5 0-2.9.7-3.7 1.9"
                        fill={favs.has(p.id) ? "#C03B32" : "none"}
                        stroke={favs.has(p.id) ? "#C03B32" : "#B8C0B4"}
                        strokeWidth="1.5"
                      />
                    </svg>
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
