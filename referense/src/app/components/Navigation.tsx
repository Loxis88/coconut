import { motion } from "motion/react";
import type { Screen } from "./data";

const ITEMS: { id: Screen; label: string; renderIcon: (active: boolean) => React.ReactNode }[] = [
  {
    id: "home",
    label: "Главная",
    renderIcon: (a) => (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <path
          d="M2 9.5L11 3l9 6.5V20a1 1 0 01-1 1H14v-5.5h-4V21H3a1 1 0 01-1-1V9.5z"
          fill={a ? "#153918" : "none"}
          stroke={a ? "#153918" : "#8A9486"}
          strokeWidth="1.6"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
  {
    id: "search",
    label: "Поиск",
    renderIcon: (a) => (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <circle cx="9.5" cy="9.5" r="6" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" />
        <path d="M14 14l5 5" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" strokeLinecap="round" />
      </svg>
    ),
  },
  {
    id: "scanner",
    label: "",
    renderIcon: () => (
      <div
        className="flex items-center justify-center"
        style={{
          width: 52,
          height: 52,
          borderRadius: "18px",
          background: "#153918",
          boxShadow: "0 6px 20px rgba(21, 57, 24, 0.35)",
        }}
      >
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <rect x="2" y="10" width="18" height="2" rx="1" fill="white" />
          {[3, 6.5, 10, 13.5, 17].map((x) => (
            <rect key={x} x={x} y="5" width="2" height="12" rx="0.8" fill="white" fillOpacity={x === 6.5 || x === 13.5 ? 1 : 0.45} />
          ))}
        </svg>
      </div>
    ),
  },
  {
    id: "history",
    label: "История",
    renderIcon: (a) => (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <circle cx="11" cy="11" r="8" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" />
        <path d="M11 7v4l2.5 2.5" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    id: "profile",
    label: "Профиль",
    renderIcon: (a) => (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <circle cx="11" cy="8.5" r="3.5" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" />
        <path d="M3.5 20c0-3.9 3.4-7 7.5-7s7.5 3.1 7.5 7" stroke={a ? "#153918" : "#8A9486"} strokeWidth="1.7" strokeLinecap="round" />
      </svg>
    ),
  },
];

export function Navigation({ current, onChange }: { current: Screen; onChange: (s: Screen) => void }) {
  return (
    <div
      className="flex items-end justify-around px-3 pt-2 pb-5"
      style={{
        background: "rgba(232, 227, 214, 0.94)",
        backdropFilter: "blur(24px)",
        borderTop: "1px solid rgba(12, 26, 9, 0.07)",
      }}
    >
      {ITEMS.map((item) => {
        const isScanner = item.id === "scanner";
        const active = current === item.id;

        return (
          <button
            key={item.id}
            onClick={() => onChange(item.id)}
            className="flex flex-col items-center gap-1"
            style={{ minWidth: 44 }}
          >
            {isScanner ? (
              <motion.div whileTap={{ scale: 0.9 }} style={{ marginBottom: "2px", marginTop: "-22px" }}>
                {item.renderIcon(active)}
              </motion.div>
            ) : (
              <>
                <div className="relative">
                  {item.renderIcon(active)}
                  {active && (
                    <motion.div
                      layoutId="nav-pip"
                      className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full"
                      style={{ background: "#153918" }}
                    />
                  )}
                </div>
                <span
                  style={{
                    fontFamily: "var(--font-body)",
                    fontWeight: active ? 600 : 400,
                    fontSize: "10px",
                    color: active ? "#153918" : "#8A9486",
                    letterSpacing: "0.01em",
                  }}
                >
                  {item.label}
                </span>
              </>
            )}
          </button>
        );
      })}
    </div>
  );
}
