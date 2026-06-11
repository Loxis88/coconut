import { useEffect, useState } from "react";
import { motion } from "motion/react";

export function SplashScreen({ onComplete }: { onComplete: () => void }) {
  const [step, setStep] = useState(0);

  useEffect(() => {
    const t1 = setTimeout(() => setStep(1), 300);
    const t2 = setTimeout(() => setStep(2), 900);
    const t3 = setTimeout(() => setStep(3), 1700);
    const t4 = setTimeout(() => onComplete(), 2900);
    return () => [t1, t2, t3, t4].forEach(clearTimeout);
  }, [onComplete]);

  return (
    <div
      className="h-full flex flex-col items-center justify-center relative overflow-hidden"
      style={{ background: "#0D1F0F" }}
    >
      {/* Concentric rings — lighthouse glow */}
      {[200, 300, 420].map((size, i) => (
        <motion.div
          key={size}
          className="absolute rounded-full"
          style={{
            width: size,
            height: size,
            border: "1px solid rgba(91,175,100,0.15)",
          }}
          initial={{ opacity: 0, scale: 0.6 }}
          animate={{ opacity: step >= 1 ? 1 : 0, scale: step >= 1 ? 1 : 0.6 }}
          transition={{ duration: 1.4, delay: i * 0.12, ease: [0.16, 1, 0.3, 1] }}
        />
      ))}

      {/* Core glow */}
      <motion.div
        className="absolute w-32 h-32 rounded-full"
        style={{ background: "radial-gradient(circle, rgba(91,175,100,0.18) 0%, transparent 70%)" }}
        initial={{ opacity: 0 }}
        animate={{ opacity: step >= 1 ? 1 : 0 }}
        transition={{ duration: 1.2 }}
      />

      {/* Lighthouse mark */}
      <motion.div
        className="relative z-10"
        initial={{ opacity: 0, y: 24, scale: 0.9 }}
        animate={{ opacity: step >= 1 ? 1 : 0, y: step >= 1 ? 0 : 24, scale: step >= 1 ? 1 : 0.9 }}
        transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
      >
        <svg width="56" height="72" viewBox="0 0 56 72" fill="none">
          {/* Beam */}
          <motion.path
            d="M28 18 L50 68 L6 68 Z"
            fill="rgba(91,175,100,0.07)"
            initial={{ opacity: 0 }}
            animate={{ opacity: step >= 2 ? 1 : 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
          />
          {/* Tower */}
          <rect x="22" y="28" width="12" height="42" rx="1.5" fill="rgba(255,255,255,0.85)" />
          <rect x="22" y="42" width="12" height="7" fill="rgba(255,255,255,0.25)" />
          {/* Lantern */}
          <rect x="18" y="18" width="20" height="13" rx="2.5" fill="white" />
          {/* Light pulse */}
          <motion.circle
            cx="28"
            cy="24"
            r="4.5"
            fill="#FFD566"
            animate={{ opacity: [1, 0.4, 1], r: [4.5, 5.5, 4.5] }}
            transition={{ duration: 1.8, repeat: Infinity, ease: "easeInOut" }}
          />
          {/* Cap */}
          <path d="M20 18 Q28 11 36 18" fill="rgba(255,255,255,0.85)" />
          {/* Base */}
          <rect x="18" y="68" width="20" height="4" rx="1" fill="rgba(255,255,255,0.55)" />
        </svg>
      </motion.div>

      {/* Brand name — Fraunces display */}
      <motion.div
        className="mt-8 text-center z-10"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: step >= 2 ? 1 : 0, y: step >= 2 ? 0 : 12 }}
        transition={{ duration: 0.7 }}
      >
        <div
          style={{
            fontFamily: "var(--font-display)",
            fontWeight: 900,
            fontSize: "44px",
            color: "white",
            letterSpacing: "0.18em",
            lineHeight: 1,
          }}
        >
          МАЯК
        </div>
        <motion.div
          style={{
            fontFamily: "var(--font-body)",
            fontSize: "12px",
            color: "rgba(255,255,255,0.35)",
            letterSpacing: "0.12em",
            marginTop: "10px",
            textTransform: "uppercase",
          }}
          initial={{ opacity: 0 }}
          animate={{ opacity: step >= 3 ? 1 : 0 }}
          transition={{ duration: 0.6 }}
        >
          Навигатор питания
        </motion.div>
      </motion.div>

      {/* Progress line */}
      <motion.div
        className="absolute bottom-16 w-16 h-px"
        style={{ background: "rgba(255,255,255,0.12)" }}
        initial={{ opacity: 0 }}
        animate={{ opacity: step >= 2 ? 1 : 0 }}
      >
        <motion.div
          className="h-full"
          style={{ background: "rgba(91,175,100,0.8)" }}
          initial={{ width: "0%" }}
          animate={{ width: step >= 2 ? "100%" : "0%" }}
          transition={{ duration: 2, ease: "linear" }}
        />
      </motion.div>
    </div>
  );
}
