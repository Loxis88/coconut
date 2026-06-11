import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function AuthScreen({ onAuth }: { onAuth: () => void }) {
  const [mode, setMode] = useState<"main" | "email">("main");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <div className="flex flex-col h-full" style={{ background: "#E8E3D6" }}>
      {/* Dark top area */}
      <div
        className="relative flex flex-col px-7 pt-16 pb-10 overflow-hidden"
        style={{
          background: "#0D1F0F",
          borderBottomLeftRadius: "40px",
          borderBottomRightRadius: "40px",
          minHeight: "46%",
        }}
      >
        {/* Ambient */}
        <div
          className="absolute top-0 right-0 w-48 h-48 rounded-full"
          style={{ background: "radial-gradient(circle, rgba(91,175,100,0.12) 0%, transparent 70%)" }}
        />

        {/* Logo row */}
        <div className="flex items-center gap-3 mb-auto">
          <svg width="28" height="36" viewBox="0 0 28 36" fill="none">
            <rect x="10" y="14" width="8" height="20" rx="1" fill="rgba(255,255,255,0.85)" />
            <rect x="10" y="21" width="8" height="4" fill="rgba(255,255,255,0.25)" />
            <rect x="6" y="8" width="16" height="8" rx="2" fill="white" />
            <circle cx="14" cy="12" r="3" fill="#FFD566" />
            <path d="M8 8 Q14 3 20 8" fill="rgba(255,255,255,0.85)" />
            <rect x="8" y="33" width="12" height="3" rx="1" fill="rgba(255,255,255,0.5)" />
          </svg>
          <span
            style={{
              fontFamily: "var(--font-display)",
              fontWeight: 900,
              fontSize: "22px",
              color: "white",
              letterSpacing: "0.15em",
            }}
          >
            МАЯК
          </span>
        </div>

        {/* Hero text */}
        <div className="mt-auto">
          <h1
            style={{
              fontFamily: "var(--font-display)",
              fontWeight: 800,
              fontSize: "36px",
              color: "white",
              lineHeight: 1.1,
              letterSpacing: "-0.02em",
              marginBottom: "10px",
            }}
          >
            Навигатор<br />
            <span style={{ color: "rgba(255,255,255,0.45)", fontStyle: "italic", fontWeight: 400 }}>
              питания
            </span>
          </h1>
          <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "rgba(255,255,255,0.35)", lineHeight: 1.6 }}>
            Ваши данные хранятся на устройстве
            <br />и не передаются третьим лицам
          </p>
        </div>
      </div>

      {/* Auth area */}
      <div className="flex-1 flex flex-col px-7 pt-8">
        <AnimatePresence mode="wait">
          {mode === "main" ? (
            <motion.div
              key="main"
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
              className="flex flex-col gap-3"
            >
              <p
                style={{
                  fontFamily: "var(--font-body)",
                  fontWeight: 700,
                  fontSize: "18px",
                  color: "#0C1A09",
                  letterSpacing: "-0.02em",
                  marginBottom: "4px",
                }}
              >
                Войдите или создайте аккаунт
              </p>

              <AuthBtn bg="#0C1A09" color="white" onClick={onAuth}>
                <AppleIcon />
                Продолжить с Apple
              </AuthBtn>

              <AuthBtn bg="white" color="#0C1A09" border onClick={onAuth}>
                <GoogleIcon />
                Продолжить с Google
              </AuthBtn>

              <div className="flex items-center gap-3 my-1">
                <div className="flex-1 h-px" style={{ background: "rgba(12,26,9,0.1)" }} />
                <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "#5E6859" }}>или</span>
                <div className="flex-1 h-px" style={{ background: "rgba(12,26,9,0.1)" }} />
              </div>

              <AuthBtn bg="transparent" color="#153918" border onClick={() => setMode("email")}>
                <MailIcon />
                Войти через Email
              </AuthBtn>

              <p
                style={{
                  fontFamily: "var(--font-body)",
                  fontSize: "11px",
                  color: "#5E6859",
                  textAlign: "center",
                  marginTop: "8px",
                  lineHeight: 1.6,
                }}
              >
                Нажимая «Продолжить», вы принимаете{" "}
                <span style={{ color: "#153918", textDecoration: "underline", textUnderlineOffset: "2px" }}>
                  Условия
                </span>{" "}
                и{" "}
                <span style={{ color: "#153918", textDecoration: "underline", textUnderlineOffset: "2px" }}>
                  Политику конфиденциальности
                </span>
              </p>
            </motion.div>
          ) : (
            <motion.div
              key="email"
              initial={{ opacity: 0, x: 24 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.3 }}
              className="flex flex-col gap-4"
            >
              <button
                onClick={() => setMode("main")}
                className="flex items-center gap-1.5 mb-1"
                style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "14px", color: "#153918" }}
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M9 3L5 7l4 4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
                Назад
              </button>

              <p style={{ fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "18px", color: "#0C1A09", letterSpacing: "-0.02em" }}>
                Email и пароль
              </p>

              <Field label="Email" type="email" value={email} onChange={setEmail} placeholder="you@example.com" />
              <Field label="Пароль" type="password" value={password} onChange={setPassword} placeholder="••••••••" />

              <button
                onClick={onAuth}
                className="mt-2 py-4 rounded-2xl active:scale-95 transition-transform w-full"
                style={{ background: "#153918", color: "white", fontFamily: "var(--font-body)", fontWeight: 700, fontSize: "16px" }}
              >
                Войти
              </button>

              <button style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "#153918", textDecoration: "underline", textUnderlineOffset: "2px", alignSelf: "center" }}>
                Забыли пароль?
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function AuthBtn({ bg, color, border, onClick, children }: {
  bg: string; color: string; border?: boolean; onClick: () => void; children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-3 w-full px-5 py-4 rounded-2xl active:scale-98 transition-transform"
      style={{
        background: bg,
        color,
        border: border ? "1.5px solid rgba(12,26,9,0.13)" : "none",
        fontFamily: "var(--font-body)",
        fontWeight: 600,
        fontSize: "15px",
        boxShadow: bg === "white" ? "0 1px 4px rgba(0,0,0,0.07)" : undefined,
      }}
    >
      {children}
    </button>
  );
}

function Field({ label, type, value, onChange, placeholder }: {
  label: string; type: string; value: string; onChange: (v: string) => void; placeholder: string;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "12px", color: "#5E6859" }}>{label}</label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full px-4 py-3.5 rounded-2xl outline-none"
        style={{
          background: "white",
          border: "1.5px solid rgba(12,26,9,0.1)",
          fontSize: "15px",
          fontFamily: "var(--font-body)",
          color: "#0C1A09",
        }}
      />
    </div>
  );
}

function AppleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="white">
      <path d="M14.2 9.4c0-2.4 2-3.5 2.1-3.6-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.1-2.9.9-3.7.9-.8 0-2-.8-3.2-.8C4.2 4.1 2.4 5.1 1.5 6.8c-2 3.3-.5 8.2 1.4 10.9.9 1.3 2 2.8 3.5 2.7 1.4-.1 1.9-.9 3.6-.9 1.7 0 2.1.9 3.6.9 1.5 0 2.5-1.4 3.4-2.7.7-1 1.3-2.1 1.7-3.3-3.6-1.4-3.5-5.8-3.5-5.9zM11.8 2.7c.8-.9 1.3-2.2 1.1-3.5-1.1.1-2.4.7-3.2 1.6-.7.8-1.3 2.1-1.1 3.3 1.2.1 2.5-.6 3.2-1.4z" />
    </svg>
  );
}

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
      <path d="M17.6 9.2c0-.7-.1-1.3-.2-2H9v3.7h4.8c-.2 1.1-.9 2-1.8 2.6v2.2h3c1.7-1.6 2.6-4 2.6-6.5z" fill="#4285F4" />
      <path d="M9 18c2.4 0 4.4-.8 5.9-2.2L11.8 13.6c-.8.5-1.8.8-2.8.8-2.2 0-4-1.5-4.7-3.4H1.2v2.3C2.7 16.1 5.7 18 9 18z" fill="#34A853" />
      <path d="M4.3 11c-.2-.5-.3-1-.3-1.5s.1-1 .3-1.5V5.7H1.2C.5 7 0 8.4 0 9.8s.5 2.8 1.2 4L4.3 11z" fill="#FBBC05" />
      <path d="M9 3.6c1.3 0 2.4.4 3.3 1.3l2.5-2.5C13.4.8 11.4 0 9 0 5.7 0 2.7 1.9 1.2 4.8l3.1 2.3C5 5.1 6.8 3.6 9 3.6z" fill="#EA4335" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
      <rect x="1.5" y="3.5" width="15" height="11" rx="2.5" stroke="#153918" strokeWidth="1.5" />
      <path d="M1.5 6.5l7.5 5 7.5-5" stroke="#153918" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}
