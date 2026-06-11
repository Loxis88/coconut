import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";

const SLIDES = [
  {
    num: "01",
    heading: "Понимайте\nчто вы едите",
    body: "МАЯК расшифровывает этикетки продуктов и объясняет состав простым и честным языком — без химического жаргона.",
    visual: <Visual1 />,
    bg: "#F4F1E8",
    ink: "#153918",
  },
  {
    num: "02",
    heading: "Сканируйте\nза секунду",
    body: "Наведите камеру на штрихкод — и получите полный научный анализ продукта до того, как положите его в корзину.",
    visual: <Visual2 />,
    bg: "#EBF3E8",
    ink: "#153918",
  },
  {
    num: "03",
    heading: "Научная\nоснова",
    body: "Каждая оценка опирается на рецензируемые исследования, критерии ВОЗ и базу данных Open Food Facts.",
    visual: <Visual3 />,
    bg: "#F4F1E8",
    ink: "#153918",
  },
  {
    num: "04",
    heading: "Найдите\nлучшую замену",
    body: "Маяк предложит более полезную альтернативу в той же категории и объяснит, чем она лучше.",
    visual: <Visual4 />,
    bg: "#EBF3E8",
    ink: "#153918",
  },
];

function Visual1() {
  return (
    <svg width="260" height="200" viewBox="0 0 260 200" fill="none">
      {/* Product label */}
      <rect x="55" y="20" width="150" height="160" rx="16" fill="white" opacity="0.7" />
      <rect x="70" y="36" width="120" height="14" rx="7" fill="#153918" opacity="0.12" />
      <rect x="70" y="58" width="88" height="9" rx="4.5" fill="#153918" opacity="0.07" />
      <rect x="70" y="74" width="104" height="9" rx="4.5" fill="#153918" opacity="0.07" />
      <rect x="70" y="90" width="72" height="9" rx="4.5" fill="#153918" opacity="0.07" />
      {/* Score bubble */}
      <circle cx="130" cy="148" r="30" fill="#153918" opacity="0.08" />
      <text x="130" y="155" textAnchor="middle" fontSize="24" fontWeight="800" fill="#153918" fontFamily="Fraunces, serif" opacity="0.85">
        87
      </text>
      {/* Green check marks */}
      {[0, 1, 2].map((i) => (
        <g key={i} transform={`translate(70, ${58 + i * 16})`}>
          <circle r="5" fill="#4A9152" opacity="0.18" />
          <path d="M-2.5 0l1.8 1.8 3.5-3.5" stroke="#1E6B28" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
        </g>
      ))}
    </svg>
  );
}

function Visual2() {
  return (
    <svg width="260" height="200" viewBox="0 0 260 200" fill="none">
      {/* Phone silhouette */}
      <rect x="95" y="10" width="70" height="120" rx="12" fill="#153918" opacity="0.08" />
      <rect x="100" y="16" width="60" height="108" rx="9" fill="white" opacity="0.5" />
      {/* Scan frame */}
      <rect x="113" y="38" width="34" height="52" rx="4" fill="none" stroke="#153918" strokeWidth="1.5" opacity="0.3" />
      {/* Corner marks */}
      {[[113,38],[147,38],[113,90],[147,90]].map(([x,y],i) => (
        <g key={i}>
          <line x1={x} y1={y} x2={x + (i%2===0?8:-8)} y2={y} stroke="#1E6B28" strokeWidth="2.5" strokeLinecap="round" />
          <line x1={x} y1={y} x2={x} y2={y + (i<2?8:-8)} stroke="#1E6B28" strokeWidth="2.5" strokeLinecap="round" />
        </g>
      ))}
      {/* Scan line */}
      <line x1="113" y1="64" x2="147" y2="64" stroke="#4A9152" strokeWidth="1.5" opacity="0.7" />
      {/* Barcode bars */}
      {[0,1,2,3,4,5,6,7].map((i) => (
        <rect key={i} x={116+i*4} y={46} width={2+(i%3)} height={36} rx="0.5" fill="#153918" opacity={0.08 + (i%3)*0.04} />
      ))}
      {/* Success flash */}
      <circle cx="130" cy="158" r="20" fill="#4A9152" opacity="0.12" />
      <path d="M122 158l5 5 11-11" stroke="#1E6B28" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function Visual3() {
  return (
    <svg width="260" height="200" viewBox="0 0 260 200" fill="none">
      {/* Circular diagram */}
      <circle cx="130" cy="100" r="72" fill="none" stroke="#153918" strokeOpacity="0.07" strokeWidth="1" />
      <circle cx="130" cy="100" r="50" fill="none" stroke="#153918" strokeOpacity="0.07" strokeWidth="1" />
      <circle cx="130" cy="100" r="28" fill="#153918" opacity="0.06" />
      <text x="130" y="104" textAnchor="middle" fontSize="13" fontWeight="700" fill="#153918" opacity="0.6" fontFamily="DM Mono, monospace">
        ВОЗ
      </text>
      {/* Data nodes */}
      {[
        { angle: -60, r: 72, label: "A" },
        { angle: 20, r: 72, label: "B" },
        { angle: 110, r: 72, label: "C" },
      ].map(({ angle, r, label }) => {
        const rad = (angle * Math.PI) / 180;
        const x = 130 + r * Math.cos(rad);
        const y = 100 + r * Math.sin(rad);
        return (
          <g key={label}>
            <line x1="130" y1="100" x2={x} y2={y} stroke="#153918" strokeOpacity="0.1" strokeWidth="1" />
            <circle cx={x} cy={y} r="16" fill="#153918" opacity="0.1" />
            <text x={x} y={y+5} textAnchor="middle" fontSize="12" fontWeight="700" fill="#153918" opacity="0.6" fontFamily="DM Mono, monospace">
              {label}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

function Visual4() {
  return (
    <svg width="260" height="200" viewBox="0 0 260 200" fill="none">
      {/* Two products comparison */}
      {[
        { x: 40, score: 28, label: "Нутелла", bad: true },
        { x: 148, score: 62, label: "7 орехов", bad: false },
      ].map(({ x, score, label, bad }) => (
        <g key={x}>
          <rect x={x} y={30} width={72} height={96} rx="12" fill={bad ? "#C03B32" : "#1E6B28"} opacity="0.07" />
          <rect x={x+8} y={38} width={56} height={40} rx="8" fill="white" opacity="0.5" />
          <text
            x={x + 36}
            y={116}
            textAnchor="middle"
            fontSize="30"
            fontWeight="900"
            fill={bad ? "#C03B32" : "#1E6B28"}
            fontFamily="Fraunces, serif"
            opacity="0.85"
          >
            {score}
          </text>
          <text x={x + 36} y={136} textAnchor="middle" fontSize="10" fill="#153918" opacity="0.5" fontFamily="DM Sans, sans-serif">
            {label}
          </text>
        </g>
      ))}
      {/* Arrow */}
      <path d="M120 80 L140 80" stroke="#1E6B28" strokeWidth="2.5" strokeLinecap="round" markerEnd="url(#arr)" />
      <defs>
        <marker id="arr" markerWidth="6" markerHeight="6" refX="5" refY="3" orient="auto">
          <path d="M0 0L6 3L0 6" fill="none" stroke="#1E6B28" strokeWidth="1.5" />
        </marker>
      </defs>
      {/* Stars on good */}
      <text x="184" y="26" fontSize="14" opacity="0.7">✦</text>
    </svg>
  );
}

export function OnboardingScreen({ onComplete }: { onComplete: () => void }) {
  const [idx, setIdx] = useState(0);
  const slide = SLIDES[idx];

  return (
    <div
      className="flex flex-col h-full transition-colors duration-500"
      style={{ background: slide.bg }}
    >
      {/* Top bar */}
      <div className="flex items-center justify-between px-6 pt-12 pb-2">
        <span
          style={{ fontFamily: "var(--font-mono)", fontSize: "12px", color: `${slide.ink}40`, letterSpacing: "0.04em" }}
        >
          {idx + 1} / {SLIDES.length}
        </span>
        <button
          onClick={onComplete}
          style={{ fontFamily: "var(--font-body)", fontWeight: 500, fontSize: "14px", color: `${slide.ink}55` }}
        >
          Пропустить
        </button>
      </div>

      {/* Illustration */}
      <div className="flex items-center justify-center" style={{ height: 220 }}>
        <AnimatePresence mode="wait">
          <motion.div
            key={idx}
            initial={{ opacity: 0, scale: 0.88 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.94 }}
            transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
          >
            {slide.visual}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Text block — editorial */}
      <div className="flex-1 flex flex-col justify-end px-7 pb-2">
        <AnimatePresence mode="wait">
          <motion.div
            key={idx}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.38 }}
          >
            {/* Slide number — mono anchor */}
            <div
              style={{
                fontFamily: "var(--font-display)",
                fontWeight: 900,
                fontSize: "96px",
                lineHeight: 0.85,
                color: `${slide.ink}08`,
                userSelect: "none",
                marginBottom: "-24px",
                letterSpacing: "-0.04em",
              }}
            >
              {slide.num}
            </div>

            <h2
              style={{
                fontFamily: "var(--font-body)",
                fontWeight: 700,
                fontSize: "28px",
                lineHeight: 1.15,
                letterSpacing: "-0.03em",
                color: slide.ink,
                whiteSpace: "pre-line",
                marginBottom: "12px",
              }}
            >
              {slide.heading}
            </h2>
            <p
              style={{
                fontFamily: "var(--font-body)",
                fontSize: "15px",
                lineHeight: 1.65,
                color: `${slide.ink}88`,
                fontWeight: 400,
              }}
            >
              {slide.body}
            </p>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom */}
      <div className="flex items-center justify-between px-7 py-8">
        {/* Dot indicator */}
        <div className="flex gap-2">
          {SLIDES.map((_, i) => (
            <button key={i} onClick={() => setIdx(i)}>
              <motion.div
                className="rounded-full"
                style={{ height: 6, background: i === idx ? slide.ink : `${slide.ink}25` }}
                animate={{ width: i === idx ? 24 : 6 }}
                transition={{ duration: 0.3, ease: "easeOut" }}
              />
            </button>
          ))}
        </div>

        {/* CTA */}
        <button
          onClick={() => idx < SLIDES.length - 1 ? setIdx(idx + 1) : onComplete()}
          className="flex items-center gap-2.5 rounded-2xl px-7 py-3.5 active:scale-95 transition-transform"
          style={{
            background: slide.ink,
            color: slide.bg,
            fontFamily: "var(--font-body)",
            fontWeight: 600,
            fontSize: "15px",
          }}
        >
          {idx < SLIDES.length - 1 ? "Далее" : "Начать"}
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M2.5 7h9M8 3.5l3.5 3.5L8 10.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>
    </div>
  );
}
