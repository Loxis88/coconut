import { useState, useRef } from "react";
import { motion, AnimatePresence, useMotionValue, useTransform, animate } from "motion/react";
import { MOCK_PRODUCTS, getScoreColor } from "./data";
import type { Product, Screen } from "./data";

type Phase = "idle" | "scanning" | "found" | "analyzing";
type InputTab = "camera" | "manual";

// Fixed panel height in px — never changes
const PANEL_H = 148;
// Full-screen expansion offset (how far up the sheet travels)
const FULL_OFFSET = 520;

export function ScannerScreen({ onNavigate }: { onNavigate: (s: Screen, p?: Product) => void }) {
  const [phase, setPhase] = useState<Phase>("idle");
  const [flash, setFlash] = useState(false);
  const [tab, setTab] = useState<InputTab>("camera");
  const [barcode, setBarcode] = useState("");
  const [expanded, setExpanded] = useState(false);
  const foundProduct = MOCK_PRODUCTS[0];

  // Sheet drag
  const sheetY = useMotionValue(0); // 0 = preview closed, negative = expanded up
  const dragStart = useRef(0);

  const expandSheet = () => {
    animate(sheetY, -FULL_OFFSET, { type: "spring", stiffness: 300, damping: 32 });
    setExpanded(true);
  };

  const collapseSheet = () => {
    animate(sheetY, 0, { type: "spring", stiffness: 300, damping: 32 });
    setExpanded(false);
  };

  const handleDragEnd = (_: never, info: { offset: { y: number }; velocity: { y: number } }) => {
    const { offset, velocity } = info;
    if (offset.y < -60 || velocity.y < -400) {
      expandSheet();
    } else if (offset.y > 60 || velocity.y > 400) {
      collapseSheet();
    } else {
      // snap back
      if (expanded) expandSheet(); else collapseSheet();
    }
  };

  const startScan = () => {
    setPhase("scanning");
    setTimeout(() => setPhase("found"), 2200);
    setTimeout(() => setPhase("analyzing"), 3000);
  };

  const openProduct = () => onNavigate("product", foundProduct);

  const submitManual = () => {
    if (barcode.trim().length < 4) return;
    setPhase("analyzing");
    setTimeout(() => setPhase("found"), 1800);
  };

  const isResult = phase === "found" || phase === "analyzing";

  // Dim overlay opacity tied to sheet position
  const overlayOpacity = useTransform(sheetY, [-FULL_OFFSET, 0], [0.55, 0]);

  return (
    <div className="flex flex-col h-full" style={{ background: "#080F09", position: "relative", overflow: "hidden" }}>

      {/* ── Header ── */}
      <div
        className="absolute top-0 left-0 right-0 flex items-center justify-between px-6 z-20"
        style={{ paddingTop: 56, paddingBottom: 16, background: "linear-gradient(to bottom, rgba(8,15,9,0.9), transparent)" }}
      >
        <button
          onClick={() => onNavigate("home")}
          className="w-9 h-9 rounded-full flex items-center justify-center"
          style={{ background: "rgba(255,255,255,0.08)", backdropFilter: "blur(8px)" }}
        >
          <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
            <path d="M9.5 3.5L5.5 7.5l4 4" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
        <span style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "15px", color: "rgba(255,255,255,0.9)" }}>Сканер</span>
        <button
          onClick={() => setFlash(f => !f)}
          className="w-9 h-9 rounded-full flex items-center justify-center"
          style={{
            background: flash ? "rgba(255,220,80,0.18)" : "rgba(255,255,255,0.08)",
            backdropFilter: "blur(8px)",
            border: flash ? "1px solid rgba(255,220,80,0.35)" : "1px solid transparent",
            transition: "all 0.2s",
          }}
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M9 1L3 9h5l-1 6 6-8H8L9 1z"
              fill={flash ? "#FFE04A" : "none"}
              stroke={flash ? "#FFE04A" : "rgba(255,255,255,0.7)"}
              strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>

      {/* ── Viewfinder ── */}
      <div className="absolute inset-0 flex items-center justify-center" style={{ bottom: PANEL_H }}>
        <div className="absolute inset-0" style={{ background: "radial-gradient(ellipse at 50% 40%, #0D1F0F 0%, #080F09 100%)" }} />
        <div className="absolute inset-0 opacity-20" style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/%3E%3C/svg%3E")`,
          backgroundSize: "180px 180px",
        }} />

        <AnimatePresence>
          {flash && (
            <motion.div className="absolute inset-0"
              style={{ background: "radial-gradient(ellipse at 50% 45%, rgba(255,220,80,0.06) 0%, transparent 70%)" }}
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
          )}
        </AnimatePresence>
        <AnimatePresence>
          {(phase === "scanning" || isResult) && (
            <motion.div className="absolute inset-0"
              style={{ background: "radial-gradient(ellipse at 50% 45%, rgba(91,175,100,0.1) 0%, transparent 65%)" }}
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.8 }} />
          )}
        </AnimatePresence>

        {/* Scan frame */}
        <div className="relative z-10" style={{ width: 248, height: 164 }}>
          {[{ top: 0, left: 0 }, { top: 0, right: 0 }, { bottom: 0, left: 0 }, { bottom: 0, right: 0 }].map((pos, i) => {
            const isRight = "right" in pos, isBottom = "bottom" in pos;
            const color = isResult ? "#5BAF64" : "rgba(255,255,255,0.65)";
            return (
              <div key={i} className="absolute" style={{
                ...pos, width: 24, height: 24,
                borderTop: isBottom ? "none" : `2.5px solid ${color}`,
                borderBottom: isBottom ? `2.5px solid ${color}` : "none",
                borderLeft: isRight ? "none" : `2.5px solid ${color}`,
                borderRight: isRight ? `2.5px solid ${color}` : "none",
                borderRadius: isRight ? (isBottom ? "0 0 6px 0" : "0 6px 0 0") : (isBottom ? "0 0 0 6px" : "6px 0 0 0"),
                transition: "border-color 0.4s",
              }} />
            );
          })}
          <AnimatePresence>
            {phase === "scanning" && (
              <motion.div className="absolute left-2 right-2 h-px"
                style={{ background: "linear-gradient(to right, transparent, #5BAF64 30%, #5BAF64 70%, transparent)", boxShadow: "0 0 8px rgba(91,175,100,0.6)" }}
                initial={{ top: "0%" }} animate={{ top: ["0%", "100%", "0%"] }}
                transition={{ duration: 1.6, repeat: Infinity, ease: "linear" }} />
            )}
          </AnimatePresence>
          <AnimatePresence>
            {isResult && (
              <motion.div className="absolute inset-4 flex items-center gap-0.5"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3 }}>
                {Array.from({ length: 40 }).map((_, i) => (
                  <div key={i} style={{ flex: 1, height: `${35 + Math.sin(i * 0.7) * 28}%`, background: "rgba(91,175,100,0.45)", borderRadius: "1px" }} />
                ))}
              </motion.div>
            )}
          </AnimatePresence>
          <AnimatePresence>
            {phase === "found" && (
              <motion.div className="absolute -inset-3 rounded-2xl"
                style={{ border: "1.5px solid rgba(91,175,100,0.4)" }}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: [0, 1, 0.6], scale: [0.9, 1.01, 1] }}
                transition={{ duration: 0.6 }} />
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* ── Dim overlay when sheet expanded ── */}
      <motion.div
        className="absolute inset-0 z-20 pointer-events-none"
        style={{ background: "#080F09", opacity: overlayOpacity }}
      />

      {/* ── Bottom area — fixed height wrapper ── */}
      <div
        className="absolute left-0 right-0 z-30"
        style={{ bottom: 0, height: PANEL_H }}
      >
        <AnimatePresence mode="wait">

          {/* IDLE + SCANNING — controls panel (fixed height) */}
          {!isResult && (
            <motion.div
              key="controls"
              className="absolute inset-0 px-4 flex flex-col justify-end pb-8"
              style={{ background: "linear-gradient(to top, rgba(8,15,9,1) 60%, transparent)" }}
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
            >
              <div className="rounded-3xl overflow-hidden" style={{ background: "#F4F0E6" }}>
                {/* Tab switcher */}
                <div className="flex" style={{ borderBottom: "1px solid rgba(12,26,9,0.08)" }}>
                  {(["camera", "manual"] as InputTab[]).map(t => {
                    const labels: Record<InputTab, string> = { camera: "Камера", manual: "Вручную" };
                    const icons: Record<InputTab, React.ReactNode> = {
                      camera: (
                        <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
                          <rect x="1" y="3.5" width="12" height="8" rx="2" stroke="currentColor" strokeWidth="1.4" />
                          <circle cx="7" cy="7.5" r="2" stroke="currentColor" strokeWidth="1.4" />
                          <path d="M5 3.5l.8-1.5h2.4L9 3.5" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
                        </svg>
                      ),
                      manual: (
                        <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
                          <rect x="1.5" y="2" width="1.2" height="10" rx="0.5" fill="currentColor" />
                          <rect x="4.2" y="2" width="0.8" height="10" rx="0.4" fill="currentColor" />
                          <rect x="6.5" y="2" width="1.5" height="10" rx="0.5" fill="currentColor" />
                          <rect x="9.5" y="2" width="0.8" height="10" rx="0.4" fill="currentColor" />
                          <rect x="11.5" y="2" width="1" height="10" rx="0.5" fill="currentColor" />
                        </svg>
                      ),
                    };
                    const active = tab === t;
                    return (
                      <button key={t} onClick={() => setTab(t)}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2.5 relative"
                        style={{ fontFamily: "var(--font-body)", fontWeight: active ? 700 : 400, fontSize: "13px", color: active ? "#0C1A09" : "#8A9486" }}>
                        {icons[t]}{labels[t]}
                        {active && (
                          <motion.div layoutId="sc-tab" className="absolute bottom-0 left-5 right-5 h-0.5 rounded-full" style={{ background: "#153918" }} />
                        )}
                      </button>
                    );
                  })}
                </div>

                {/* Tab body — fixed height so panel doesn't jump */}
                <div style={{ height: 76, position: "relative", overflow: "hidden" }}>
                  <AnimatePresence mode="wait" initial={false}>
                    {tab === "camera" ? (
                      <motion.div key="cam"
                        className="absolute inset-0 flex items-center justify-between px-5"
                        initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }}
                        transition={{ duration: 0.15 }}
                      >
                        <div>
                          <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px", color: "#0C1A09", marginBottom: "2px" }}>
                            {phase === "scanning" ? "Ищем штрихкод…" : "Автоскан активен"}
                          </p>
                          <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>
                            {phase === "scanning" ? "Держите упаковку ровно" : "Наведи камеру на штрих-код."}
                          </p>
                        </div>
                        <motion.button
                          whileTap={{ scale: 0.92 }}
                          onClick={phase === "idle" ? startScan : undefined}
                          className="w-13 h-13 rounded-full flex items-center justify-center flex-shrink-0"
                          style={{
                            width: 52, height: 52,
                            background: phase === "scanning"
                              ? "rgba(21,57,24,0.15)"
                              : "linear-gradient(135deg, #4A9152, #1E6B28)",
                            boxShadow: phase === "scanning" ? "none" : "0 6px 20px rgba(30,107,40,0.4)",
                            transition: "all 0.3s",
                          }}
                        >
                          {phase === "scanning" ? (
                            <motion.div
                              className="w-5 h-5 rounded-full border-2"
                              style={{ borderColor: "#153918", borderTopColor: "transparent" }}
                              animate={{ rotate: 360 }}
                              transition={{ duration: 0.9, repeat: Infinity, ease: "linear" }}
                            />
                          ) : (
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                              <rect x="3" y="5" width="18" height="14" rx="3" stroke="white" strokeWidth="1.8" />
                              <circle cx="12" cy="12" r="3.5" stroke="white" strokeWidth="1.8" />
                              <path d="M8 5l1-2h6l1 2" stroke="white" strokeWidth="1.6" strokeLinecap="round" />
                            </svg>
                          )}
                        </motion.button>
                      </motion.div>
                    ) : (
                      <motion.div key="man"
                        className="absolute inset-0 flex items-center gap-2 px-4"
                        initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}
                        transition={{ duration: 0.15 }}
                      >
                        <div
                          className="flex-1 flex items-center gap-2 px-3 rounded-2xl"
                          style={{ background: "rgba(12,26,9,0.06)", border: "1.5px solid rgba(12,26,9,0.1)", height: 44 }}
                        >
                          <svg width="12" height="12" viewBox="0 0 13 13" fill="none" style={{ flexShrink: 0, opacity: 0.35 }}>
                            <rect x="0.5" y="1" width="1.2" height="11" rx="0.5" fill="#0C1A09" />
                            <rect x="3.2" y="1" width="0.8" height="11" rx="0.4" fill="#0C1A09" />
                            <rect x="5.5" y="1" width="1.5" height="11" rx="0.5" fill="#0C1A09" />
                            <rect x="8.5" y="1" width="0.8" height="11" rx="0.4" fill="#0C1A09" />
                            <rect x="10.8" y="1" width="1.2" height="11" rx="0.5" fill="#0C1A09" />
                          </svg>
                          <input
                            type="number" inputMode="numeric"
                            value={barcode}
                            onChange={e => setBarcode(e.target.value)}
                            onKeyDown={e => e.key === "Enter" && submitManual()}
                            placeholder="4600000000000"
                            className="flex-1 outline-none bg-transparent"
                            style={{ fontFamily: "var(--font-mono)", fontSize: "14px", color: "#0C1A09", letterSpacing: "0.04em" }}
                          />
                          {barcode.length > 0 && (
                            <button onClick={() => setBarcode("")}>
                              <svg width="13" height="13" viewBox="0 0 14 14" fill="none">
                                <circle cx="7" cy="7" r="6" fill="rgba(12,26,9,0.1)" />
                                <path d="M4.5 4.5l5 5M9.5 4.5l-5 5" stroke="#5E6859" strokeWidth="1.3" strokeLinecap="round" />
                              </svg>
                            </button>
                          )}
                        </div>
                        <motion.button
                          whileTap={{ scale: 0.95 }} onClick={submitManual}
                          className="rounded-2xl flex items-center justify-center flex-shrink-0"
                          style={{
                            width: 52, height: 44,
                            background: barcode.trim().length >= 4 ? "#153918" : "rgba(21,57,24,0.12)",
                            fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "14px",
                            color: barcode.trim().length >= 4 ? "white" : "rgba(21,57,24,0.3)",
                            transition: "all 0.2s",
                          }}>
                          OK
                        </motion.button>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </div>
            </motion.div>
          )}

          {/* RESULT — draggable product sheet */}
          {isResult && (
            <motion.div
              key="sheet"
              className="absolute left-0 right-0"
              style={{
                bottom: 0,
                y: sheetY,
                // Sheet is taller than PANEL_H so expanded content has room
                height: FULL_OFFSET + PANEL_H + 32,
              }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
            >
              {/* Drag handle + preview — always visible area */}
              <motion.div
                drag="y"
                dragConstraints={{ top: -FULL_OFFSET, bottom: 0 }}
                dragElastic={0.12}
                onDragEnd={handleDragEnd}
                style={{ touchAction: "none" }}
              >
                {/* Pull handle */}
                <div className="flex justify-center pt-3 pb-0 cursor-grab active:cursor-grabbing"
                  style={{ background: "#F4F0E6", borderRadius: "24px 24px 0 0" }}>
                  <div className="w-10 h-1 rounded-full" style={{ background: "rgba(12,26,9,0.15)" }} />
                </div>

                {/* Preview card */}
                <div
                  className="flex items-center gap-4 px-4 pb-4 pt-3 cursor-grab active:cursor-grabbing"
                  style={{ background: "#F4F0E6", borderLeft: `4px solid ${getScoreColor(foundProduct.score)}` }}
                  onClick={expanded ? openProduct : undefined}
                >
                  <div className="flex-shrink-0 rounded-2xl overflow-hidden" style={{ width: 60, height: 60, background: "#DDD8CB" }}>
                    <img src={foundProduct.image} alt={foundProduct.name} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "#5E6859", textTransform: "uppercase", letterSpacing: "0.07em", marginBottom: "2px" }}>
                      {foundProduct.brand} · {foundProduct.category}
                    </p>
                    <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "15px", color: "#0C1A09", letterSpacing: "-0.02em", lineHeight: 1.25 }}>
                      {foundProduct.name}
                    </p>
                    <p style={{ fontFamily: "var(--font-body)", fontSize: "11px", marginTop: "3px", fontWeight: 600, color: phase === "analyzing" ? "#5E6859" : "#4A9152" }}>
                      {phase === "analyzing" ? "Анализируем…" : "✓ Штрихкод найден · свайп вверх"}
                    </p>
                  </div>
                  <div className="flex-shrink-0">
                    <ScoreArc score={foundProduct.score} />
                  </div>
                </div>
              </motion.div>

              {/* Expanded content — full product card detail */}
              <div style={{ background: "#F4F0E6", padding: "0 16px 32px" }}>
                <div style={{ height: 1, background: "rgba(12,26,9,0.07)", marginBottom: 16 }} />

                {/* Macros */}
                <div className="grid grid-cols-4 gap-2 mb-4">
                  {[
                    { label: "Ккал", val: foundProduct.calories },
                    { label: "Белки", val: `${foundProduct.protein}г` },
                    { label: "Жиры", val: `${foundProduct.fat}г` },
                    { label: "Угл.", val: `${foundProduct.carbs}г` },
                  ].map(m => (
                    <div key={m.label} className="rounded-2xl p-3 text-center" style={{ background: "#E8E3D6" }}>
                      <p style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: "18px", color: "#0C1A09", lineHeight: 1 }}>{m.val}</p>
                      <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "#5E6859", marginTop: 2 }}>{m.label}</p>
                    </div>
                  ))}
                </div>

                <motion.button
                  whileTap={{ scale: 0.97 }}
                  onClick={openProduct}
                  className="w-full py-4 rounded-2xl"
                  style={{ background: "#153918", fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px", color: "white", boxShadow: "0 8px 24px rgba(21,57,24,0.35)" }}
                >
                  Открыть карточку
                </motion.button>
              </div>
            </motion.div>
          )}

        </AnimatePresence>
      </div>
    </div>
  );
}

function ScoreArc({ score }: { score: number }) {
  const size = 58, r = 23, circ = 2 * Math.PI * r;
  const arc = circ * 0.7, dash = (score / 100) * arc;
  const color = score >= 70 ? "#1E6B28" : score >= 40 ? "#B87D28" : "#C03B32";
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={29} cy={29} r={r} fill="none" stroke="rgba(12,26,9,0.07)" strokeWidth="4"
          strokeDasharray={`${arc} ${circ - arc}`} strokeLinecap="round" transform="rotate(126 29 29)" />
        <motion.circle cx={29} cy={29} r={r} fill="none" stroke={color} strokeWidth="4"
          strokeDasharray={`${dash} ${circ - dash}`} strokeLinecap="round" transform="rotate(126 29 29)"
          initial={{ strokeDasharray: `0 ${circ}` }}
          animate={{ strokeDasharray: `${dash} ${circ - dash}` }}
          transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }} />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "16px", color: "#0C1A09", lineHeight: 1 }}>{score}</span>
      </div>
    </div>
  );
}
