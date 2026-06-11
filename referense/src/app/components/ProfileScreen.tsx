import { useState } from "react";
import { motion } from "motion/react";

const DIET_OPTIONS = ["Без ограничений", "Вегетарианство", "Веганство", "Без глютена", "Без лактозы", "Кето"];
const ALLERGENS = ["Глютен", "Молоко", "Яйца", "Арахис", "Орехи", "Соя", "Морепродукты"];

export function ProfileScreen() {
  const [diet, setDiet] = useState("Без ограничений");
  const [allergens, setAllergens] = useState<Set<string>>(new Set());
  const [notifs, setNotifs] = useState(true);
  const [weekly, setWeekly] = useState(true);

  const toggleAllergen = (a: string) => {
    setAllergens((prev) => { const s = new Set(prev); s.has(a) ? s.delete(a) : s.add(a); return s; });
  };

  return (
    <div className="flex flex-col h-full" style={{ background: "#E8E3D6" }}>
      <div className="flex-1 overflow-y-auto">
        {/* Hero */}
        <div
          className="relative px-6 pt-14 pb-7 overflow-hidden"
          style={{ background: "#0D1F0F" }}
        >
          <div className="absolute top-0 right-0 w-40 h-40 rounded-full opacity-10" style={{ background: "radial-gradient(#5BAF64, transparent)" }} />

          <div className="flex items-center gap-4 mb-6">
            <div
              className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0"
              style={{ background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.12)" }}
            >
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "22px", color: "white" }}>А</span>
            </div>
            <div className="flex-1">
              <h2 style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "18px", color: "white", letterSpacing: "-0.02em" }}>
                Александра К.
              </h2>
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "rgba(255,255,255,0.35)", marginTop: "2px" }}>
                С нами с мая 2025
              </p>
            </div>
            <button
              className="w-9 h-9 rounded-xl flex items-center justify-center"
              style={{ background: "rgba(255,255,255,0.1)" }}
            >
              <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
                <path d="M10.5 1.5L13.5 4.5l-8 8H2.5v-3l8-8z" stroke="white" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>

          {/* Key stats */}
          <div className="grid grid-cols-3 gap-2">
            {[
              { n: "23", label: "Продуктов" },
              { n: "74", label: "Индекс", highlight: true },
              { n: "7", label: "Дней подряд" },
            ].map((s) => (
              <div key={s.label} className="rounded-2xl p-3 text-center" style={{ background: "rgba(255,255,255,0.07)" }}>
                <p style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: "24px", color: s.highlight ? "#5BAF64" : "white", lineHeight: 1 }}>
                  {s.n}
                </p>
                <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", color: "rgba(255,255,255,0.3)", marginTop: "2px", letterSpacing: "0.04em" }}>
                  {s.label}
                </p>
              </div>
            ))}
          </div>
        </div>

        <div className="px-5 pt-5 pb-8 flex flex-col gap-5">
          {/* Diet */}
          <Section title="Тип питания">
            <div className="flex flex-wrap gap-2">
              {DIET_OPTIONS.map((d) => (
                <button
                  key={d}
                  onClick={() => setDiet(d)}
                  className="px-3.5 py-2 rounded-xl transition-all"
                  style={{
                    background: diet === d ? "#153918" : "rgba(12,26,9,0.06)",
                    color: diet === d ? "white" : "#5E6859",
                    fontFamily: "var(--font-body)",
                    fontWeight: diet === d ? 600 : 400,
                    fontSize: "13px",
                  }}
                >
                  {d}
                </button>
              ))}
            </div>
          </Section>

          {/* Allergens */}
          <Section title="Аллергены">
            <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859", marginBottom: "10px", lineHeight: 1.5 }}>
              Маяк предупредит, если продукт содержит выбранные аллергены
            </p>
            <div className="flex flex-wrap gap-2">
              {ALLERGENS.map((a) => (
                <button
                  key={a}
                  onClick={() => toggleAllergen(a)}
                  className="px-3.5 py-2 rounded-xl transition-all"
                  style={{
                    background: allergens.has(a) ? "rgba(192,59,50,0.1)" : "rgba(12,26,9,0.06)",
                    color: allergens.has(a) ? "#C03B32" : "#5E6859",
                    fontFamily: "var(--font-body)",
                    fontWeight: allergens.has(a) ? 600 : 400,
                    fontSize: "13px",
                    border: allergens.has(a) ? "1px solid rgba(192,59,50,0.2)" : "1px solid transparent",
                  }}
                >
                  {a}
                </button>
              ))}
            </div>
          </Section>

          {/* Settings */}
          <Section title="Настройки">
            <div className="flex flex-col">
              <Toggle label="Push-уведомления" sub="Советы и напоминания" on={notifs} onChange={setNotifs} />
              <Toggle label="Еженедельный отчёт" sub="По воскресеньям" on={weekly} onChange={setWeekly} />
            </div>
          </Section>

          {/* About */}
          <Section title="О приложении">
            {[
              { label: "Источники данных", icon: "🔬" },
              { label: "Политика конфиденциальности", icon: "🔒" },
              { label: "Условия использования", icon: "📄" },
              { label: "Обратная связь", icon: "💬" },
            ].map((item) => (
              <div
                key={item.label}
                className="flex items-center gap-3 py-3"
                style={{ borderBottom: "1px solid rgba(12,26,9,0.07)" }}
              >
                <span style={{ fontSize: "16px" }}>{item.icon}</span>
                <p style={{ flex: 1, fontFamily: "var(--font-body)", fontSize: "14px", color: "#0C1A09" }}>{item.label}</p>
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M5 3l4 4-4 4" stroke="#8A9486" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
            ))}
            <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#8A9486", marginTop: "12px", textAlign: "center" }}>
              МАЯК v2.0.0 · 2026
            </p>
          </Section>
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p style={{ fontFamily: "var(--font-mono)", fontSize: "10px", color: "#5E6859", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "10px" }}>
        {title}
      </p>
      <div className="rounded-2xl p-4" style={{ background: "#F4F0E6", boxShadow: "0 1px 3px rgba(0,0,0,0.04)" }}>
        {children}
      </div>
    </div>
  );
}

function Toggle({ label, sub, on, onChange }: { label: string; sub: string; on: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="flex items-center gap-3 py-3" style={{ borderBottom: "1px solid rgba(12,26,9,0.07)" }}>
      <div className="flex-1">
        <p style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "14px", color: "#0C1A09" }}>{label}</p>
        <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#5E6859" }}>{sub}</p>
      </div>
      <button
        onClick={() => onChange(!on)}
        style={{ width: 44, height: 26, borderRadius: 13, background: on ? "#153918" : "#B8C0B4", transition: "background 0.25s", position: "relative", flexShrink: 0 }}
      >
        <motion.div
          style={{ width: 18, height: 18, borderRadius: "50%", background: "white", position: "absolute", top: 4 }}
          animate={{ left: on ? 22 : 4 }}
          transition={{ duration: 0.22, ease: "easeInOut" }}
        />
      </button>
    </div>
  );
}
