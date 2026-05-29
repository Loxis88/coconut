// coconut-screens.jsx — Phone screens for the Coconut app design.
// All screens take the AndroidDevice interior (~396 × ~828) and lay out
// content with a 20px gutter. No real photos — abstract FoodThumb + SVG.

const PHONE_W = 412;
const PHONE_H = 892;
const Pad = ({ children, style }) => (
  <div style={{ padding: '20px 20px 0', ...style }}>{children}</div>
);

// ─────────────────────────────────────────────────────────────
// 1 · WELCOME / SPLASH
// ─────────────────────────────────────────────────────────────
function ScreenWelcome() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        {/* hero: oversized coconut on warm gradient blob */}
        <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', inset: -60, background: 'radial-gradient(circle at 50% 40%, #BEF26455 0%, transparent 60%)' }} />
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <CoconutMark size={220} gid="welcome-g" />
          </div>
          {/* floating mini-scores */}
          <FloatChip score={92} top={70} left={28} rot={-8} />
          <FloatChip score={48} top={120} right={36} rot={6} />
          <FloatChip score={71} bottom={140} left={36} rot={4} />
          <FloatChip score={88} bottom={90} right={40} rot={-5} />
        </div>
        <div style={{ padding: '0 28px 36px' }}>
          <div style={{ fontSize: 56, fontWeight: 700, color: COCO.ink, letterSpacing: -2.5, lineHeight: 0.95 }}>
            Coconut.
          </div>
          <div style={{ fontSize: 19, color: COCO.ink2, marginTop: 10, marginBottom: 24, lineHeight: 1.3 }}>
            Crack open every bite. Get an honest score on anything you eat — in one scan.
          </div>
          <Pill kind="ink" size="lg" full>Get started <Ic.arrow /></Pill>
          <div style={{ textAlign: 'center', marginTop: 14, fontSize: 14, color: COCO.muted, fontWeight: 600 }}>
            I already have an account
          </div>
        </div>
      </div>
    </AndroidDevice>
  );
}
function FloatChip({ score, top, left, right, bottom, rot }) {
  return (
    <div style={{
      position: 'absolute', top, left, right, bottom,
      transform: `rotate(${rot}deg)`,
    }}>
      <ScoreChip score={score} big />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2 · GOALS
// ─────────────────────────────────────────────────────────────
function ScreenGoals() {
  const goals = [
    { label: 'Eat more whole foods', emoji: '🌱', sel: true },
    { label: 'Cut added sugar', sel: true },
    { label: 'Less ultra-processed', sel: false },
    { label: 'High protein', sel: false },
    { label: 'Stable energy', sel: true },
    { label: 'Just curious', sel: false },
  ];
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
            <button style={iconBtn}><Ic.back /></button>
            <div style={{ display: 'flex', gap: 6 }}>
              <Dot on /><Dot on /><Dot /></div>
            <div style={{ width: 40 }} />
          </div>
          <div style={{ fontSize: 38, fontWeight: 700, color: COCO.ink, letterSpacing: -1.5, lineHeight: 1.02 }}>
            What's your<br/>healthy <em style={{ fontStyle: 'italic', color: COCO.emeraldDeep }}>vibe?</em>
          </div>
          <div style={{ fontSize: 15, color: COCO.muted, marginTop: 10, marginBottom: 24 }}>
            Pick all that fit. We'll weight your scores so they actually mean something to you.
          </div>
        </Pad>
        <div style={{ flex: 1, padding: '0 20px', display: 'flex', flexWrap: 'wrap', gap: 10, alignContent: 'flex-start' }}>
          {goals.map((g, i) => (
            <div key={i} style={{
              padding: '14px 18px', borderRadius: 18,
              background: g.sel ? COCO.ink : '#fff',
              color: g.sel ? '#fff' : COCO.ink,
              border: g.sel ? 'none' : `1.5px solid ${COCO.hairline}`,
              fontSize: 16, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 8,
            }}>
              {g.sel && <Ic.check style={{ width: 16, height: 16 }} />}
              {g.label}
            </div>
          ))}
        </div>
        <div style={{ padding: 20 }}>
          <Pill kind="brand" size="lg" full>Continue <Ic.arrow /></Pill>
        </div>
      </div>
    </AndroidDevice>
  );
}
const iconBtn = {
  width: 40, height: 40, borderRadius: 20, border: 'none',
  background: 'rgba(26,20,16,0.06)', color: COCO.ink,
  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
};
function Dot({ on }) {
  return <div style={{ width: 24, height: 6, borderRadius: 3, background: on ? COCO.ink : 'rgba(26,20,16,0.15)' }} />;
}

// ─────────────────────────────────────────────────────────────
// 3 · DAILY TARGET
// ─────────────────────────────────────────────────────────────
function ScreenTarget() {
  const score = 75;
  const t = tier(score);
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 28 }}>
            <button style={iconBtn}><Ic.back /></button>
            <div style={{ display: 'flex', gap: 6 }}><Dot on /><Dot on /><Dot on /></div>
            <div style={{ width: 40 }} />
          </div>
          <div style={{ fontSize: 38, fontWeight: 700, color: COCO.ink, letterSpacing: -1.5, lineHeight: 1.02 }}>
            Aim for a<br/>daily average.
          </div>
          <div style={{ fontSize: 15, color: COCO.muted, marginTop: 10 }}>
            We'll nudge you (gently) when your day is trending low.
          </div>
        </Pad>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <ScoreRing score={score} size={210} thickness={18} label={false} />
          <div style={{ fontSize: 18, fontWeight: 700, color: t.color, textTransform: 'uppercase', letterSpacing: 3, marginTop: -8 }}>{t.label} day</div>
        </div>
        <Pad style={{ paddingBottom: 0 }}>
          {/* track */}
          <div style={{ position: 'relative', marginTop: 8 }}>
            <div style={{ height: 8, borderRadius: 4, background: 'rgba(26,20,16,0.08)' }} />
            <div style={{ position: 'absolute', top: 0, left: 0, height: 8, borderRadius: 4, width: '75%', background: COCO.gradient }} />
            <div style={{ position: 'absolute', top: -8, left: 'calc(75% - 12px)', width: 24, height: 24, borderRadius: 12, background: '#fff', boxShadow: '0 2px 8px rgba(0,0,0,0.18)', border: `3px solid ${COCO.ink}` }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: COCO.muted, marginTop: 10, fontWeight: 600 }}>
            <span>Chill (40)</span><span>Steady (60)</span><span>Sharp (90)</span>
          </div>
        </Pad>
        <div style={{ padding: 20 }}>
          <Pill kind="brand" size="lg" full>Lock it in <Ic.check /></Pill>
        </div>
      </div>
    </AndroidDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// 4 · HOME — TODAY
// ─────────────────────────────────────────────────────────────
function ScreenHomeToday() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        {/* Top app row */}
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 18 }}>
            <CoconutMark size={36} gid="home-mark" />
            <div style={{ flex: 1, fontSize: 22, fontWeight: 700, color: COCO.ink, letterSpacing: -0.5 }}>Coconut</div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: '#fff', borderRadius: 999, padding: '6px 12px' }}>
              <span style={{ color: COCO.coral }}><Ic.flame style={{ width: 16, height: 16 }} /></span>
              <span style={{ fontSize: 14, fontWeight: 700, color: COCO.ink }}>12</span>
            </div>
            <button style={iconBtn}><Ic.bell /></button>
          </div>
        </Pad>

        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 12 }}>
          <Pad style={{ paddingTop: 0 }}>
            <div style={{ fontSize: 14, color: COCO.muted, fontWeight: 600, marginBottom: 4 }}>Today · Tue, May 28</div>
            <div style={{ fontSize: 34, fontWeight: 700, color: COCO.ink, letterSpacing: -1, lineHeight: 1.05 }}>
              Hi Theo —<br/>
              you're <span style={{ color: COCO.emeraldDeep }}>on track.</span>
            </div>
          </Pad>

          {/* Today's score hero card */}
          <Pad style={{ paddingTop: 18 }}>
            <Card style={{ background: COCO.gradient, padding: 22, borderRadius: 28, color: COCO.brownDeep, position: 'relative', overflow: 'hidden' }}>
              <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.18 }}>
                <CoconutMark size={180} gid="hero-mark" />
              </div>
              <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 18 }}>
                <ScoreRing score={78} size={120} thickness={11} label={false} />
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase' }}>Today's avg</div>
                  <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.8, marginTop: 4, lineHeight: 1.1 }}>Solid <br/>so&nbsp;far.</div>
                  <div style={{ fontSize: 13, fontWeight: 600, marginTop: 6, opacity: 0.8 }}>3 scans · +6 from yesterday</div>
                </div>
              </div>
            </Card>
          </Pad>

          {/* Weekly mini bars */}
          <Pad style={{ paddingTop: 14 }}>
            <Card style={{ padding: 18 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
                <div style={{ fontSize: 16, fontWeight: 700, color: COCO.ink }}>This week</div>
                <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 600 }}>avg 72</div>
              </div>
              <WeekBars values={[68, 80, 55, 74, 84, 90, 78]} />
            </Card>
          </Pad>

          {/* Recent scans */}
          <Pad style={{ paddingTop: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
              <div style={{ fontSize: 18, fontWeight: 700, color: COCO.ink, letterSpacing: -0.3 }}>Today's scans</div>
              <span style={{ fontSize: 13, fontWeight: 600, color: COCO.muted }}>See all</span>
            </div>
            <Card style={{ padding: 6 }}>
              <FoodRow name="Oatly Barista" sub="Oat milk · 240ml" score={82} thumb="O" />
              <Hr m={0} />
              <FoodRow name="Picky chocolate bar" sub="Snack · 35g" score={42} thumb="P" />
              <Hr m={0} />
              <FoodRow name="Skyr blueberry" sub="Yogurt · 170g" score={88} thumb="S" />
            </Card>
          </Pad>
        </div>

        <BottomNav active="home" />
      </div>
    </AndroidDevice>
  );
}

function FoodRow({ name, sub, score, thumb, time }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 12px' }}>
      <FoodThumb seed={thumb} label={thumb} size={48} radius={14} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 700, color: COCO.ink, letterSpacing: -0.2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</div>
        <div style={{ fontSize: 12, color: COCO.muted, fontWeight: 500, marginTop: 1 }}>{sub}{time ? ` · ${time}` : ''}</div>
      </div>
      <ScoreChip score={score} />
    </div>
  );
}

function WeekBars({ values }) {
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const max = 100;
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', height: 86 }}>
      {values.map((v, i) => {
        const t = tier(v);
        const today = i === values.length - 1;
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
            <div style={{ flex: 1, width: '100%', display: 'flex', alignItems: 'flex-end' }}>
              <div style={{
                width: '100%', height: `${(v / max) * 100}%`, borderRadius: 8,
                background: t.color, position: 'relative',
                outline: today ? `2px solid ${COCO.ink}` : 'none',
                outlineOffset: 2,
              }} />
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, color: today ? COCO.ink : COCO.muted }}>{labels[i]}</div>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5 · HOME — STREAK variant
// ─────────────────────────────────────────────────────────────
function ScreenHomeStreak() {
  const days = [
    { d: 'M', s: 71 }, { d: 'T', s: 84 }, { d: 'W', s: 58 }, { d: 'T', s: 79 },
    { d: 'F', s: 88 }, { d: 'S', s: 65 }, { d: 'S', s: 78 },
  ];
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.ink, display: 'flex', flexDirection: 'column', color: '#fff' }}>
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 22 }}>
            <CoconutMark size={32} gid="streak-mark" />
            <div style={{ flex: 1, fontSize: 20, fontWeight: 700, letterSpacing: -0.3 }}>Coconut</div>
            <button style={{ ...iconBtn, background: 'rgba(255,255,255,0.1)', color: '#fff' }}><Ic.bell /></button>
          </div>
        </Pad>

        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 12 }}>
          {/* Streak hero */}
          <Pad style={{ paddingTop: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: COCO.lime, textTransform: 'uppercase', letterSpacing: 3 }}>Streak</div>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 18, marginTop: 4 }}>
              <div style={{ fontSize: 120, fontWeight: 700, letterSpacing: -6, lineHeight: 0.9, fontVariantNumeric: 'tabular-nums', background: COCO.gradient, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>12</div>
              <div style={{ paddingBottom: 18 }}>
                <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.5 }}>days</div>
                <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.6)', fontWeight: 600, marginTop: 2 }}>scanning daily</div>
              </div>
            </div>
          </Pad>

          {/* 7-day strip */}
          <Pad style={{ paddingTop: 22 }}>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'space-between' }}>
              {days.map((day, i) => {
                const t = tier(day.s);
                const today = i === days.length - 1;
                return (
                  <div key={i} style={{
                    flex: 1, background: today ? '#fff' : 'rgba(255,255,255,0.08)',
                    borderRadius: 16, padding: '12px 6px', textAlign: 'center',
                  }}>
                    <div style={{ fontSize: 11, fontWeight: 700, color: today ? COCO.muted : 'rgba(255,255,255,0.5)', marginBottom: 8 }}>{day.d}</div>
                    <div style={{
                      width: 28, height: 28, borderRadius: 14, margin: '0 auto',
                      background: t.color, color: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 12, fontWeight: 700,
                    }}>{day.s}</div>
                  </div>
                );
              })}
            </div>
          </Pad>

          {/* Today block */}
          <Pad style={{ paddingTop: 24 }}>
            <div style={{
              background: 'rgba(255,255,255,0.06)', borderRadius: 28, padding: 20,
              border: '1px solid rgba(255,255,255,0.08)',
            }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: 'rgba(255,255,255,0.55)', textTransform: 'uppercase', letterSpacing: 2 }}>Today's avg</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
                <div style={{ fontSize: 64, fontWeight: 700, letterSpacing: -3, lineHeight: 1, color: '#fff' }}>78</div>
                <div style={{ fontSize: 22, fontWeight: 600, color: 'rgba(255,255,255,0.5)' }}>/100</div>
                <div style={{ marginLeft: 'auto', fontSize: 13, fontWeight: 700, color: COCO.lime, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  ↑ 6 vs yest.
                </div>
              </div>
              <div style={{ height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.1)', marginTop: 14, position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', inset: 0, width: '78%', background: COCO.gradient, borderRadius: 3 }} />
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 16, fontSize: 13, fontWeight: 600 }}>
                <span style={{ color: 'rgba(255,255,255,0.6)' }}>3 scans logged</span>
                <span style={{ color: COCO.lime }}>Goal 75 ✓</span>
              </div>
            </div>
          </Pad>

          <Pad style={{ paddingTop: 22 }}>
            <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 10, letterSpacing: -0.3 }}>Latest</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <DarkRow name="Skyr blueberry" sub="9:22 am" score={88} thumb="S" />
              <DarkRow name="Oatly Barista" sub="11:04 am" score={82} thumb="O" />
            </div>
          </Pad>
        </div>

        <div style={{ background: '#fff' }}>
          <BottomNav active="home" />
        </div>
      </div>
    </AndroidDevice>
  );
}

function DarkRow({ name, sub, score, thumb }) {
  return (
    <div style={{
      background: 'rgba(255,255,255,0.06)', borderRadius: 18, padding: 12,
      display: 'flex', alignItems: 'center', gap: 12, border: '1px solid rgba(255,255,255,0.06)',
    }}>
      <FoodThumb seed={thumb} label={thumb} size={42} radius={12} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 700, color: '#fff' }}>{name}</div>
        <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.55)', fontWeight: 500, marginTop: 1 }}>{sub}</div>
      </div>
      <ScoreChip score={score} />
    </div>
  );
}

Object.assign(window, {
  ScreenWelcome, ScreenGoals, ScreenTarget, ScreenHomeToday, ScreenHomeStreak,
  PHONE_W, PHONE_H, Pad, iconBtn, FoodRow, WeekBars, DarkRow, FloatChip,
});
