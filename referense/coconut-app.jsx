// coconut-app.jsx — Top-level canvas that lays out all 13 phone screens
// across 6 sections (Onboarding, Home, Capture, Detail, Swaps, Social).

const AB_W = 412;
const AB_H = 892;

function CoconutCanvas() {
  return (
    <DesignCanvas>
      {/* Title postit */}
      <DCSection id="brand" title="Coconut · Android · v1" subtitle="A food-healthiness app · 0–100 score, Material You + bold playful">
        <DCArtboard id="brand-card" label="Brand sheet" width={760} height={460}>
          <div style={{ height: '100%', background: COCO.cream, padding: 36, display: 'flex', flexDirection: 'column', gap: 18, fontFamily: '"Bricolage Grotesque", sans-serif' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <CoconutMark size={64} gid="brand-mark" />
              <div>
                <div style={{ fontSize: 48, fontWeight: 700, color: COCO.ink, letterSpacing: -2, lineHeight: 1 }}>Coconut.</div>
                <div style={{ fontSize: 16, color: COCO.muted, marginTop: 6, fontWeight: 600 }}>Crack open every bite.</div>
              </div>
            </div>

            {/* tier swatches */}
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 }}>Score tiers</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
                {[[92,'Crisp'],[71,'Solid'],[48,'Iffy'],[24,'Skip']].map(([s, l]) => {
                  const t = tier(s);
                  return (
                    <div key={l} style={{ background: '#fff', borderRadius: 18, padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
                      <ScoreChip score={s} big />
                      <div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: COCO.ink, letterSpacing: -0.2 }}>{l}</div>
                        <div style={{ fontSize: 11, color: COCO.muted, fontWeight: 600 }}>{s >= 80 ? '80–100' : s >= 60 ? '60–79' : s >= 40 ? '40–59' : '0–39'}</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 16 }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 }}>Type</div>
                <div style={{ background: '#fff', borderRadius: 18, padding: 16 }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: COCO.ink, letterSpacing: -1.2, lineHeight: 1 }}>Bricolage Grotesque</div>
                  <div style={{ fontSize: 14, color: COCO.muted, fontWeight: 600, marginTop: 4 }}>Display 700 · Heading 600 · Body 500</div>
                </div>
              </div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 2, marginBottom: 8 }}>Palette</div>
                <div style={{ background: '#fff', borderRadius: 18, padding: 12, display: 'flex', gap: 6 }}>
                  {['#FFF6E8','#FBEFD9','#1A1410','#BEF264','#10B981','#F59E0B','#F97316','#E11D48'].map(c => (
                    <div key={c} style={{ flex: 1, height: 48, borderRadius: 10, background: c, border: c === '#FFF6E8' ? `1px solid ${COCO.hairline}` : 'none' }} />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </DCArtboard>

        <DCPostIt top={-12} right={20} rotate={3} width={220}>
          13 screens · 6 flows.<br/>Each phone is 412×892.<br/>Tap any to focus, ←/→ to step.
        </DCPostIt>
      </DCSection>

      <DCSection id="onboarding" title="Onboarding" subtitle="First-run · pick a goal · set a daily target">
        <DCArtboard id="welcome" label="01 · Welcome" width={AB_W} height={AB_H}><ScreenWelcome /></DCArtboard>
        <DCArtboard id="goals" label="02 · Pick your vibe" width={AB_W} height={AB_H}><ScreenGoals /></DCArtboard>
        <DCArtboard id="target" label="03 · Daily target" width={AB_W} height={AB_H}><ScreenTarget /></DCArtboard>
      </DCSection>

      <DCSection id="home" title="Home" subtitle="Two takes — warm cream vs. dark streak hero">
        <DCArtboard id="home-today" label="A · Today (default)" width={AB_W} height={AB_H}><ScreenHomeToday /></DCArtboard>
        <DCArtboard id="home-streak" label="B · Streak hero (dark)" width={AB_W} height={AB_H}><ScreenHomeStreak /></DCArtboard>
      </DCSection>

      <DCSection id="capture" title="Capture & search" subtitle="Three ways to log a food">
        <DCArtboard id="scan-cam" label="01 · Barcode scan" width={AB_W} height={AB_H}><ScreenScanCamera /></DCArtboard>
        <DCArtboard id="analyzing" label="02 · Analyzing" width={AB_W} height={AB_H}><ScreenAnalyzing /></DCArtboard>
        <DCArtboard id="search" label="03 · Search results" width={AB_W} height={AB_H}><ScreenSearch /></DCArtboard>
      </DCSection>

      <DCSection id="detail" title="Food detail" subtitle="Two presentations of the 0–100 breakdown">
        <DCArtboard id="detail-list" label="A · Axes as bars (skip tier)" width={AB_W} height={AB_H}><ScreenDetailList /></DCArtboard>
        <DCArtboard id="detail-radar" label="B · Radar chart (crisp tier)" width={AB_W} height={AB_H}><ScreenDetailAxes /></DCArtboard>
      </DCSection>

      <DCSection id="swaps" title="Recommendations & swaps" subtitle="One-up your last scan, or browse a category">
        <DCArtboard id="swap-card" label="A · Better-swap card" width={AB_W} height={AB_H}><ScreenSwapCard /></DCArtboard>
        <DCArtboard id="swap-browse" label="B · Browse swaps" width={AB_W} height={AB_H}><ScreenSwapBrowse /></DCArtboard>
      </DCSection>

      <DCSection id="social" title="Friends" subtitle="Lightweight social — feed + streak race">
        <DCArtboard id="feed" label="01 · Activity feed" width={AB_W} height={AB_H}><ScreenFeed /></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<CoconutCanvas />);
