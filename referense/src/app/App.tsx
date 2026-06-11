import { useState } from "react";
import { AnimatePresence, motion } from "motion/react";

const MAYAK_VARS = `
  :root {
    --mk-bg: #E8E3D6;
    --mk-fg: #0C1A09;
    --mk-card: #F4F0E6;
    --mk-muted: #DDD8CB;
    --mk-muted-fg: #5E6859;
    --mk-primary: #153918;
    --mk-accent: #B87D28;
    --mk-score-excellent: #1E6B28;
    --mk-score-good: #4A9152;
    --mk-score-moderate: #B87D28;
    --mk-score-poor: #C03B32;
    --mk-nova-1: #1E6B28;
    --mk-nova-2: #4A9152;
    --mk-nova-3: #B87D28;
    --mk-nova-4: #C03B32;
    --font-display: 'Fraunces', Georgia, serif;
    --font-body: 'DM Sans', system-ui, sans-serif;
    --font-mono: 'DM Mono', 'Courier New', monospace;
  }
  * { -webkit-font-smoothing: antialiased; }
  body { font-family: var(--font-body); background: var(--mk-bg); }
  ::-webkit-scrollbar { width: 0; height: 0; }
`;
import { SplashScreen } from "./components/SplashScreen";
import { OnboardingScreen } from "./components/OnboardingScreen";
import { AuthScreen } from "./components/AuthScreen";
import { HomeScreen } from "./components/HomeScreen";
import { ScannerScreen } from "./components/ScannerScreen";
import { ProductScreen } from "./components/ProductScreen";
import { SearchScreen } from "./components/SearchScreen";
import { HistoryScreen } from "./components/HistoryScreen";
import { ProfileScreen } from "./components/ProfileScreen";
import { Navigation } from "./components/Navigation";
import type { Screen, Product } from "./components/data";

type Phase = "splash" | "onboarding" | "auth" | "app";

export default function App() {
  const [phase, setPhase] = useState<Phase>("splash");
  const [screen, setScreen] = useState<Screen>("home");
  const [productStack, setProductStack] = useState<Product[]>([]);
  const [screenHistory, setScreenHistory] = useState<Screen[]>([]);

  const navigateTo = (target: Screen, product?: Product) => {
    if (target === "product" && product) setProductStack((prev) => [...prev, product]);
    setScreenHistory((prev) => [...prev, screen]);
    setScreen(target);
  };

  const goBack = () => {
    const prev = screenHistory[screenHistory.length - 1] ?? "home";
    setScreenHistory((h) => h.slice(0, -1));
    if (screen === "product") setProductStack((s) => s.slice(0, -1));
    setScreen(prev);
  };

  const handleNav = (target: Screen) => {
    setProductStack([]);
    setScreenHistory([]);
    setScreen(target);
  };

  const currentProduct = productStack[productStack.length - 1];
  const showNav = phase === "app" && screen !== "scanner" && screen !== "product";

  return (
    <div
      className="flex items-center justify-center min-h-screen w-full"
      style={{ background: "#111" }}
    >
      <style>{MAYAK_VARS}</style>
      {/* Phone frame */}
      <div
        className="relative flex flex-col overflow-hidden"
        style={{
          width: 390,
          height: 844,
          borderRadius: 52,
          boxShadow: [
            "0 0 0 1px rgba(255,255,255,0.06)",
            "0 0 0 10px #1A1A1A",
            "0 0 0 11px rgba(255,255,255,0.04)",
            "0 48px 120px rgba(0,0,0,0.8)",
            "0 24px 60px rgba(0,0,0,0.5)",
          ].join(", "),
          background: "#E8E3D6",
        }}
      >
        {/* Status bar */}
        {phase === "app" && (
          <div
            className="flex-shrink-0 flex items-center justify-between px-7"
            style={{ height: 44, background: "transparent" }}
          >
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: "15px", color: "#0C1A09" }}>
              9:41
            </span>
            <div style={{ width: 120, height: 32, borderRadius: 20, background: "#0C1A09", position: "absolute", left: "50%", transform: "translateX(-50%)", top: 6 }} />
            <div className="flex items-center gap-1.5 z-10">
              <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
                <rect x="0" y="5" width="3" height="7" rx="1" fill="#0C1A09" opacity="0.4" />
                <rect x="4.5" y="3" width="3" height="9" rx="1" fill="#0C1A09" opacity="0.6" />
                <rect x="9" y="0.5" width="3" height="11.5" rx="1" fill="#0C1A09" opacity="0.8" />
                <rect x="13.5" y="0.5" width="3" height="11.5" rx="1" fill="#0C1A09" />
              </svg>
              <svg width="26" height="12" viewBox="0 0 26 12" fill="none">
                <rect x="0.5" y="0.5" width="22" height="11" rx="3.5" stroke="#0C1A09" strokeOpacity="0.35" />
                <rect x="2" y="2" width="17" height="8" rx="2" fill="#0C1A09" opacity="0.85" />
                <path d="M24 4v4a2 2 0 000-4z" fill="#0C1A09" opacity="0.4" />
              </svg>
            </div>
          </div>
        )}

        {/* Screens */}
        <div className="flex-1 overflow-hidden flex flex-col">
          <AnimatePresence mode="wait">
            {phase === "splash" && (
              <Screen_ key="splash" exit={{ opacity: 0 }}>
                <SplashScreen onComplete={() => setPhase("onboarding")} />
              </Screen_>
            )}
            {phase === "onboarding" && (
              <Screen_ key="onboarding" initial={{ opacity: 0 }} exit={{ opacity: 0, x: -24 }}>
                <OnboardingScreen onComplete={() => setPhase("auth")} />
              </Screen_>
            )}
            {phase === "auth" && (
              <Screen_ key="auth" initial={{ opacity: 0, x: 32 }} exit={{ opacity: 0 }}>
                <AuthScreen onAuth={() => setPhase("app")} />
              </Screen_>
            )}
            {phase === "app" && (
              <motion.div
                key="app"
                className="flex flex-col flex-1 overflow-hidden"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
              >
                <div className="flex-1 overflow-hidden flex flex-col">
                  <AnimatePresence mode="wait">
                    {screen === "home" && (
                      <Slide key="home"><HomeScreen onNavigate={navigateTo} /></Slide>
                    )}
                    {screen === "scanner" && (
                      <Slide key="scanner"><ScannerScreen onNavigate={navigateTo} /></Slide>
                    )}
                    {screen === "product" && currentProduct && (
                      <Slide key={`product-${currentProduct.id}`}>
                        <ProductScreen product={currentProduct} onNavigate={navigateTo} onBack={goBack} />
                      </Slide>
                    )}
                    {screen === "search" && (
                      <Slide key="search"><SearchScreen onNavigate={navigateTo} /></Slide>
                    )}
                    {screen === "history" && (
                      <Slide key="history"><HistoryScreen onNavigate={navigateTo} /></Slide>
                    )}
                    {screen === "profile" && (
                      <Slide key="profile"><ProfileScreen /></Slide>
                    )}
                  </AnimatePresence>
                </div>

                <AnimatePresence>
                  {showNav && (
                    <motion.div
                      initial={{ y: 80 }}
                      animate={{ y: 0 }}
                      exit={{ y: 80 }}
                      transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                    >
                      <Navigation current={screen} onChange={handleNav} />
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Home indicator */}
        {phase === "app" && (
          <div className="flex justify-center pb-2 pt-0.5 flex-shrink-0">
            <div className="w-32 h-1 rounded-full" style={{ background: "rgba(12,26,9,0.18)" }} />
          </div>
        )}
      </div>
    </div>
  );
}

function Screen_({ children, initial = { opacity: 0 }, exit }: {
  children: React.ReactNode;
  initial?: object;
  exit?: object;
}) {
  return (
    <motion.div
      className="flex flex-col h-full"
      initial={initial}
      animate={{ opacity: 1, x: 0 }}
      exit={exit ?? { opacity: 0 }}
      transition={{ duration: 0.38, ease: [0.16, 1, 0.3, 1] }}
    >
      {children}
    </motion.div>
  );
}

function Slide({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      className="flex flex-col flex-1 overflow-hidden"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -6 }}
      transition={{ duration: 0.22, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
