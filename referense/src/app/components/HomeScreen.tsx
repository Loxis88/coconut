import { motion } from "motion/react";
import { MOCK_PRODUCTS, getScoreColor, getScoreLabel } from "./data";
import type { Product, Screen } from "./data";

interface HomeScreenProps {
  onNavigate: (screen: Screen, product?: Product) => void;
}

const WEEKLY_SCORE = 74;

const MACRO_DATA = [
  { label: "Белки", pct: 78, good: true },
  { label: "Клетчатка", pct: 44, good: true },
  { label: "Сахар", pct: 63, good: false },
  { label: "Добавки", pct: 22, good: false },
];


export function HomeScreen({ onNavigate }: HomeScreenProps) {
  const scoreColor = getScoreColor(WEEKLY_SCORE);
  const pct = WEEKLY_SCORE / 100;

  return (
    <div className="flex-1 overflow-y-auto" style={{ background: "#E8E3D6" }}>

      {/* ── Hero ────────────────────────────────────────────── */}
      <div className="px-6 pt-14 pb-6">
        {/* Greeting row */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "#5E6859", letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: "2px" }}>
              Среда, 11 июня
            </p>
            <h1 style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "22px", color: "#0C1A09", letterSpacing: "-0.02em" }}>
              Привет, Александра
            </h1>
          </div>
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center"
            style={{ background: "#153918" }}
          >
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: "16px", color: "white" }}>А</span>
          </div>
        </div>

        {/* Food index card — editorial anchor */}
        <div
          className="rounded-3xl overflow-hidden"
          style={{ background: "#0D1F0F" }}
        >
          <div className="px-6 pt-7 pb-5">
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "rgba(255,255,255,0.35)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>
              Индекс питания · 7 дней
            </p>

            {/* The big editorial number */}
            <div className="flex items-end gap-4 mb-5">
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
                style={{
                  fontFamily: "var(--font-display)",
                  fontWeight: 900,
                  fontSize: "88px",
                  lineHeight: 0.9,
                  color: "#5BAF64",
                  letterSpacing: "-0.04em",
                }}
              >
                {WEEKLY_SCORE}
              </motion.div>
              <div className="pb-2">
                <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px", color: "rgba(255,255,255,0.8)" }}>
                  {getScoreLabel(WEEKLY_SCORE)}
                </p>
                <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "rgba(255,255,255,0.35)" }}>из 100</p>
                <div className="flex items-center gap-1 mt-1">
                  <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                    <path d="M5 8V2M2 5l3-3 3 3" stroke="#5BAF64" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                  <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "#5BAF64" }}>+5 за неделю</span>
                </div>
              </div>
            </div>

            {/* Progress track */}
            <div className="mb-5">
              <div className="h-1.5 rounded-full" style={{ background: "rgba(255,255,255,0.1)" }}>
                <motion.div
                  className="h-full rounded-full"
                  style={{ background: "#5BAF64" }}
                  initial={{ width: "0%" }}
                  animate={{ width: `${WEEKLY_SCORE}%` }}
                  transition={{ duration: 1.2, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
                />
              </div>
            </div>

            {/* Macro bars */}
            <div className="grid grid-cols-2 gap-x-6 gap-y-2.5">
              {MACRO_DATA.map((m) => (
                <div key={m.label}>
                  <div className="flex justify-between mb-1">
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "11px", color: "rgba(255,255,255,0.45)" }}>{m.label}</span>
                    <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: m.good ? "#5BAF64" : "#D49842" }}>{m.pct}%</span>
                  </div>
                  <div className="h-1 rounded-full" style={{ background: "rgba(255,255,255,0.08)" }}>
                    <div
                      className="h-full rounded-full"
                      style={{ width: `${m.pct}%`, background: m.good ? "#5BAF64" : "#D49842" }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>

      {/* ── Recent scans ───────────────────────────────────── */}
      <div className="px-6 mb-6">
        <SectionHeader title="Последние сканы" action="Все" onAction={() => onNavigate("history")} />

        <div className="flex flex-col gap-2.5">
          {MOCK_PRODUCTS.slice(0, 3).map((p, i) => (
            <motion.button
              key={p.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => onNavigate("product", p)}
              className="w-full flex items-center gap-4 p-4 rounded-2xl text-left active:scale-98 transition-transform"
              style={{ background: "#F4F0E6", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}
            >
              <div className="w-12 h-12 rounded-xl overflow-hidden flex-shrink-0" style={{ background: "#DDD8CB" }}>
                <img src={p.image} alt={p.name} className="w-full h-full object-cover" />
              </div>
              <div className="flex-1 min-w-0">
                <p style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "14px", color: "#0C1A09" }} className="truncate">
                  {p.name}
                </p>
                <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{p.brand}</p>
                <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", marginTop: "1px" }}>{p.scannedAt}</p>
              </div>
              {/* Score badge */}
              <div
                className="flex flex-col items-center flex-shrink-0 w-12"
                style={{ padding: "6px 0" }}
              >
                <span
                  style={{
                    fontFamily: "var(--font-display)",
                    fontWeight: 900,
                    fontSize: "24px",
                    color: getScoreColor(p.score),
                    lineHeight: 1,
                  }}
                >
                  {p.score}
                </span>
                <span
                  style={{
                    fontFamily: "var(--font-mono)",
                    fontSize: "9px",
                    color: getScoreColor(p.score),
                    letterSpacing: "0.03em",
                    marginTop: "1px",
                  }}
                >
                  {getScoreLabel(p.score)}
                </span>
              </div>
            </motion.button>
          ))}
        </div>
      </div>

    </div>
  );
}

function SectionHeader({ title, action, onAction }: { title: string; action?: string; onAction?: () => void }) {
  return (
    <div className="flex items-center justify-between mb-3">
      <h3 style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px", color: "#0C1A09", letterSpacing: "-0.02em" }}>
        {title}
      </h3>
      {action && (
        <button
          onClick={onAction}
          style={{ fontFamily: "var(--font-body)", fontWeight: 500, fontSize: "13px", color: "#153918" }}
        >
          {action} →
        </button>
      )}
    </div>
  );
}
