import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import type { Product, Screen } from "./data";
import { getScoreColor, getScoreLabel, getScoreBg } from "./data";

type Tab = "overview" | "alternatives";

const NOVA_COLORS = ["", "#1E6B28", "#4A9152", "#B87D28", "#C03B32"];

export function ProductScreen({
  product,
  onNavigate,
  onBack,
}: {
  product: Product;
  onNavigate: (s: Screen, p?: Product) => void;
  onBack: () => void;
}) {
  const [tab, setTab] = useState<Tab>("overview");
  const [faved, setFaved] = useState(false);
  const sc = getScoreColor(product.score);

  const cardAccent = product.score >= 70 ? "#1E6B28" : product.score >= 40 ? "#B87D28" : "#C03B32";
  const cardAccentBg = product.score >= 70 ? "rgba(30,107,40,0.07)" : product.score >= 40 ? "rgba(184,125,40,0.07)" : "rgba(192,59,50,0.07)";

  // Полный состав одной строкой (как на этикетке)
  const ingredientText = product.ingredients.map((i) => i.name).join(", ");

  return (
    <div className="flex flex-col h-full" style={{ background: "#E8E3D6" }}>

      {/* ── Шапка ───────────────────────────────────────── */}
      <div
        className="flex-shrink-0 flex items-center justify-between px-5"
        style={{ paddingTop: 52, paddingBottom: 12 }}
      >
        <button
          onClick={onBack}
          className="w-9 h-9 rounded-full flex items-center justify-center"
          style={{ background: "rgba(12,26,9,0.08)" }}
        >
          <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
            <path d="M9.5 3.5L5.5 7.5l4 4" stroke="#0C1A09" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        <button
          onClick={() => setFaved(!faved)}
          className="w-9 h-9 rounded-full flex items-center justify-center"
          style={{ background: "rgba(12,26,9,0.08)" }}
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M8 14L1.8 8C.8 7 .5 5.5 1 4.2A3.8 3.8 0 014.7 2c1.3 0 2.5.6 3.3 1.6A4.3 4.3 0 018 14z"
              fill={faved ? "#C03B32" : "none"} stroke="#0C1A09" strokeWidth="1.5" />
            <path d="M8 14l6.2-6C15.2 7 15.5 5.5 15 4.2A3.8 3.8 0 0011.3 2c-1.3 0-2.5.6-3.3 1.6"
              fill={faved ? "#C03B32" : "none"} stroke="#0C1A09" strokeWidth="1.5" />
          </svg>
        </button>
      </div>

      {/* Весь контент скроллится */}
      <div className="flex-1 overflow-y-auto">

        {/* ── Карточка продукта: thumbnail + название + оценка ── */}
        <div className="px-4 mb-3">
          <div className="rounded-3xl p-4 flex items-center gap-4"
            style={{ background: "#F4F0E6", boxShadow: `0 2px 12px rgba(0,0,0,0.07)`, borderLeft: `4px solid ${cardAccent}` }}>

            {/* Квадратный thumbnail 80×80 */}
            <div
              className="flex-shrink-0 rounded-2xl overflow-hidden"
              style={{ width: 80, height: 80, background: "#DDD8CB" }}
            >
              <img
                src={product.image}
                alt={product.name}
                style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}
              />
            </div>

            {/* Название и бренд */}
            <div className="flex-1 min-w-0">
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#5E6859", textTransform: "uppercase", letterSpacing: "0.07em", marginBottom: "3px" }}>
                {product.brand} · {product.category}
              </p>
              <h2 style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "17px", color: "#0C1A09", letterSpacing: "-0.02em", lineHeight: 1.25 }}>
                {product.name}
              </h2>
            </div>

            {/* Оценка */}
            <div className="flex-shrink-0">
              <ScoreArc score={product.score} />
            </div>
          </div>
        </div>

        {/* ── Tabs (sticky) ───────────────────────────────── */}
        <div
          className="px-4 sticky top-0 z-10"
          style={{ background: "#E8E3D6" }}
        >
          <div className="flex" style={{ borderBottom: "1px solid rgba(12,26,9,0.08)" }}>
            {(["overview", "alternatives"] as Tab[]).map((t) => {
              const labels: Record<Tab, string> = { overview: "Обзор", alternatives: "Альтернативы" };
              const active = tab === t;
              return (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  className="flex-1 py-3 relative"
                  style={{
                    fontFamily: "var(--font-body)",
                    fontWeight: active ? 600 : 400,
                    fontSize: "14px",
                    color: active ? "#0C1A09" : "#8A9486",
                  }}
                >
                  {labels[t]}
                  {active && (
                    <motion.div
                      layoutId="tab-line"
                      className="absolute bottom-0 left-4 right-4 h-0.5 rounded-full"
                      style={{ background: "#153918" }}
                    />
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* ── Tab content ─────────────────────────────────── */}
        <div className="px-4 pt-4 pb-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={tab}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.2 }}
            >
              {tab === "overview" && (
                <OverviewTab product={product} ingredientText={ingredientText} />
              )}
              {tab === "alternatives" && (
                <AlternativesTab product={product} onNavigate={onNavigate} />
              )}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
}

/* ── ОБЗОР ──────────────────────────────────────────────────── */
function OverviewTab({ product, ingredientText }: { product: Product; ingredientText: string }) {
  return (
    <div className="flex flex-col gap-4">

      {/* КБЖУ */}
      <Card>
        <Label>Калорийность · {product.servingSize}</Label>
        <div className="flex items-baseline gap-2 mt-2 mb-4">
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "52px", color: "#0C1A09", lineHeight: 1, letterSpacing: "-0.03em" }}>
            {product.calories}
          </span>
          <span style={{ fontFamily: "var(--font-body)", fontSize: "14px", color: "#5E6859" }}>ккал</span>
        </div>

        {/* Макро плашки */}
        <div className="grid grid-cols-3 gap-2 mb-4">
          {[
            { label: "Белки", val: product.protein, unit: "г" },
            { label: "Жиры", val: product.fat, unit: "г" },
            { label: "Углеводы", val: product.carbs, unit: "г" },
          ].map((m) => (
            <div key={m.label} className="rounded-xl p-3" style={{ background: "#E8E3D6" }}>
              <p style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: "20px", color: "#0C1A09", lineHeight: 1 }}>
                {m.val}
              </p>
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#5E6859", marginTop: "3px" }}>
                {m.label}, {m.unit}
              </p>
            </div>
          ))}
        </div>

        {/* Детальные строки */}
        {[
          { label: "Сахар", val: product.sugar, unit: "г", max: 30, warn: product.sugar > 15, warnText: "Превышает рекомендуемую норму" },
          { label: "Клетчатка", val: product.fiber, unit: "г", max: 30, warn: false, warnText: "" },
          { label: "Соль", val: product.salt, unit: "г", max: 2, warn: product.salt > 1.2, warnText: "Превышает норму ВОЗ" },
        ].map((d) => (
          <div key={d.label} className="mb-3 last:mb-0">
            <div className="flex justify-between mb-1">
              <div className="flex items-center gap-2">
                <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{d.label}</span>
                {d.warn && (
                  <span style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "#C03B32", background: "rgba(192,59,50,0.1)", padding: "1px 5px", borderRadius: "4px" }}>
                    много
                  </span>
                )}
              </div>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", color: d.warn ? "#C03B32" : "#5E6859" }}>
                {d.val} {d.unit}
              </span>
            </div>
            <div className="h-1 rounded-full" style={{ background: "rgba(12,26,9,0.07)" }}>
              <div
                className="h-full rounded-full"
                style={{ width: `${Math.min((d.val / d.max) * 100, 100)}%`, background: d.warn ? "#C03B32" : "#4A9152" }}
              />
            </div>
            {d.warn && d.warnText && (
              <p style={{ fontFamily: "var(--font-body)", fontSize: "11px", color: "#C03B32", marginTop: "4px", opacity: 0.85 }}>
                {d.warnText}
              </p>
            )}
          </div>
        ))}
      </Card>

      {/* Пищевые добавки — всегда показывается */}
      <Card>
        <Label>Пищевые добавки</Label>
        {product.additives.length === 0 ? (
          <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#4A9152", marginTop: "8px" }}>
            Пищевых добавок не обнаружено
          </p>
        ) : (
          <div className="mt-3 flex flex-col gap-2.5">
            {product.additives.map((a) => {
              const riskColor = a.risk === "high" ? "#C03B32" : a.risk === "moderate" ? "#B87D28" : "#1E6B28";
              return (
                <div key={a.code} className="flex items-start gap-3">
                  <div
                    className="flex-shrink-0 px-2 py-0.5 rounded-md mt-0.5"
                    style={{ background: `${riskColor}15` }}
                  >
                    <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", fontWeight: 500, color: riskColor }}>
                      {a.code}
                    </span>
                  </div>
                  <div>
                    <span style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "13px", color: "#0C1A09" }}>
                      {a.name}
                    </span>
                    {" — "}
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#5E6859" }}>
                      {a.description}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>

      {/* Состав — всегда в самом низу */}
      <Card>
        <Label>Состав</Label>
        <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#3A5040", lineHeight: 1.65, marginTop: "8px" }}>
          {ingredientText}
        </p>
      </Card>

    </div>
  );
}

/* ── АЛЬТЕРНАТИВЫ ───────────────────────────────────────────── */
function AlternativesTab({ product, onNavigate }: { product: Product; onNavigate: (s: Screen, p?: any) => void }) {
  if (!product.alternatives.length) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-3 text-center">
        <div className="w-14 h-14 rounded-2xl flex items-center justify-center" style={{ background: "rgba(21,57,24,0.08)" }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M12 3l2.5 5.5 6 .9-4.3 4.2 1 5.9L12 16.8l-5.2 2.7 1-5.9L3.5 9.4l6-.9z"
              stroke="#153918" strokeWidth="1.8" strokeLinejoin="round" />
          </svg>
        </div>
        <p style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "15px", color: "#0C1A09" }}>
          Это уже лучший выбор
        </p>
        <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#5E6859", maxWidth: 220 }}>
          Маяк не нашёл более полезной альтернативы в этой категории
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#5E6859" }}>
        Более полезные варианты в категории «{product.category}»
      </p>
      {product.alternatives.map((alt) => (
        <div
          key={alt.id}
          className="flex items-center gap-4 p-4 rounded-2xl"
          style={{ background: "#F4F0E6", boxShadow: "0 1px 4px rgba(0,0,0,0.05)" }}
        >
          {/* Строго квадратная картинка */}
          <div
            className="flex-shrink-0 rounded-xl overflow-hidden"
            style={{ width: 56, height: 56, background: "#DDD8CB" }}
          >
            <img
              src={alt.image}
              alt={alt.name}
              style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}
            />
          </div>
          <div className="flex-1 min-w-0">
            <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "14px", color: "#0C1A09" }}>{alt.name}</p>
            <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{alt.brand}</p>
            <div className="flex items-center gap-2 mt-1.5">
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "#8A9486" }}>
                Сейчас: {product.score}
              </span>
              <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
                <path d="M1 5h14M10 1l5 4-5 4" stroke="#1E6B28" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "16px", color: "#1E6B28" }}>
                {alt.score}
              </span>
            </div>
          </div>
          <div
            className="w-11 h-11 rounded-2xl flex items-center justify-center flex-shrink-0"
            style={{ background: getScoreBg(alt.score) }}
          >
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "18px", color: getScoreColor(alt.score) }}>
              {alt.score}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}

/* ── Helpers ────────────────────────────────────────────────── */
function ScoreArc({ score }: { score: number }) {
  const size = 68;
  const r = 28;
  const circ = 2 * Math.PI * r;
  const arc = circ * 0.7;
  const dash = (score / 100) * arc;
  const color = getScoreColor(score);
  return (
    <div className="relative flex-shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={34} cy={34} r={r} fill="none" stroke="rgba(12,26,9,0.07)" strokeWidth="5"
          strokeDasharray={`${arc} ${circ - arc}`} strokeLinecap="round"
          transform={`rotate(126 34 34)`} />
        <motion.circle
          cx={34} cy={34} r={r} fill="none" stroke={color} strokeWidth="5"
          strokeDasharray={`${dash} ${circ - dash}`} strokeLinecap="round"
          transform={`rotate(126 34 34)`}
          initial={{ strokeDasharray: `0 ${circ}` }}
          animate={{ strokeDasharray: `${dash} ${circ - dash}` }}
          transition={{ duration: 1, ease: [0.16, 1, 0.3, 1], delay: 0.1 }}
        />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "20px", color: "#0C1A09", lineHeight: 1 }}>
          {score}
        </span>
      </div>
    </div>
  );
}

function Badge({ label, color }: { label: string; color: string }) {
  return (
    <div className="px-2.5 py-1 rounded-lg" style={{ background: `${color}15`, border: `1px solid ${color}25` }}>
      <span style={{ fontFamily: "var(--font-mono)", fontWeight: 500, fontSize: "10px", color }}>{label}</span>
    </div>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-2xl p-4" style={{ background: "#F4F0E6", boxShadow: "0 1px 4px rgba(0,0,0,0.05)" }}>
      {children}
    </div>
  );
}

function Label({ children, color }: { children: React.ReactNode; color?: string }) {
  return (
    <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: color ?? "#5E6859", textTransform: "uppercase", letterSpacing: "0.08em" }}>
      {children}
    </p>
  );
}
