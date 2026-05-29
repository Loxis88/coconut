// coconut-screens-2.jsx — Capture flow, detail, swaps, social.

// ─────────────────────────────────────────────────────────────
// 6 · SCAN — camera view
// ─────────────────────────────────────────────────────────────
function ScreenScanCamera() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H} dark>
      <div style={{ height: '100%', background: '#0c0a08', display: 'flex', flexDirection: 'column', color: '#fff', position: 'relative' }}>
        {/* faux camera feed: blurry gradient stand-in */}
        <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 30% 40%, #5a4a3e 0%, #1a1410 65%, #0a0805 100%)' }} />
        <div style={{ position: 'absolute', inset: 0, background: 'repeating-linear-gradient(135deg, rgba(255,255,255,0.02) 0 2px, transparent 2px 6px)' }} />

        {/* Stand-in product silhouette */}
        <div style={{ position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center', filter: 'blur(0.5px)' }}>
          <div style={{
            width: 140, height: 220, borderRadius: '20px 20px 8px 8px',
            background: 'linear-gradient(180deg, rgba(255,200,150,0.35) 0%, rgba(120,80,50,0.45) 100%)',
            boxShadow: 'inset 0 0 30px rgba(0,0,0,0.4)',
          }}>
            <div style={{ height: 30, background: 'rgba(200,160,90,0.4)', margin: 24, borderRadius: 4 }} />
            <div style={{ height: 6, background: 'rgba(0,0,0,0.4)', margin: '40px 24px 0', borderRadius: 2 }} />
            <div style={{ height: 6, background: 'rgba(0,0,0,0.4)', margin: '8px 24px 0', borderRadius: 2 }} />
          </div>
        </div>

        {/* Top bar */}
        <div style={{ position: 'relative', padding: '16px 20px', display: 'flex', alignItems: 'center', gap: 10, zIndex: 2 }}>
          <button style={{ ...iconBtn, background: 'rgba(255,255,255,0.15)', color: '#fff', backdropFilter: 'blur(8px)' }}><Ic.close /></button>
          <div style={{ flex: 1 }} />
          <button style={{ ...iconBtn, background: 'rgba(255,255,255,0.15)', color: '#fff', backdropFilter: 'blur(8px)' }}><Ic.flash /></button>
        </div>

        {/* Scan reticle */}
        <div style={{ position: 'relative', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2 }}>
          <div style={{ width: 250, height: 250, position: 'relative' }}>
            {/* corner brackets */}
            {[[0,0,'tl'],[0,1,'tr'],[1,0,'bl'],[1,1,'br']].map(([y,x,k]) => (
              <div key={k} style={{
                position: 'absolute',
                top: y === 0 ? 0 : 'auto', bottom: y === 1 ? 0 : 'auto',
                left: x === 0 ? 0 : 'auto', right: x === 1 ? 0 : 'auto',
                width: 36, height: 36,
                borderTop: y === 0 ? `4px solid ${COCO.lime}` : 'none',
                borderBottom: y === 1 ? `4px solid ${COCO.lime}` : 'none',
                borderLeft: x === 0 ? `4px solid ${COCO.lime}` : 'none',
                borderRight: x === 1 ? `4px solid ${COCO.lime}` : 'none',
                borderRadius: y === 0 ? (x === 0 ? '14px 0 0 0' : '0 14px 0 0') : (x === 0 ? '0 0 0 14px' : '0 0 14px 0'),
              }} />
            ))}
            {/* scan line */}
            <div style={{ position: 'absolute', left: 8, right: 8, top: '50%', height: 2, background: COCO.lime, boxShadow: `0 0 14px ${COCO.lime}`, borderRadius: 2 }} />
          </div>
        </div>

        {/* Hint pill */}
        <div style={{ position: 'absolute', left: 0, right: 0, bottom: 260, display: 'flex', justifyContent: 'center', zIndex: 2 }}>
          <div style={{ background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(10px)', borderRadius: 999, padding: '8px 16px', fontSize: 13, fontWeight: 600 }}>
            Center the barcode
          </div>
        </div>

        {/* Bottom action sheet */}
        <div style={{
          position: 'relative', zIndex: 2,
          background: '#fff', color: COCO.ink,
          borderRadius: '28px 28px 0 0', padding: '18px 20px 24px',
          boxShadow: '0 -8px 30px rgba(0,0,0,0.35)',
        }}>
          {/* mode tabs */}
          <div style={{ display: 'flex', gap: 6, background: COCO.cream, borderRadius: 999, padding: 4, marginBottom: 16 }}>
            <ModeTab icon={<Ic.scan />} label="Barcode" active />
            <ModeTab icon={<Ic.camera />} label="Photo" />
            <ModeTab icon={<Ic.search />} label="Search" />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: -0.4 }}>Aim. Tap. Score.</div>
              <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 500, marginTop: 2 }}>Hold steady for half a second.</div>
            </div>
            <button style={{
              width: 70, height: 70, borderRadius: 35,
              background: COCO.gradient, border: '4px solid #fff',
              boxShadow: '0 8px 20px rgba(16,185,129,0.45)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: COCO.brownDeep,
            }}><Ic.scan /></button>
          </div>
        </div>
      </div>
    </AndroidDevice>
  );
}
function ModeTab({ icon, label, active }) {
  return (
    <div style={{
      flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      padding: '8px 0', borderRadius: 999,
      background: active ? '#fff' : 'transparent',
      color: active ? COCO.ink : COCO.muted,
      fontSize: 13, fontWeight: 700,
      boxShadow: active ? '0 1px 4px rgba(0,0,0,0.08)' : 'none',
    }}>
      <span style={{ display: 'inline-flex', width: 16, height: 16 }}>
        {React.cloneElement(icon, { width: 16, height: 16 })}
      </span>
      {label}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 7 · ANALYZING
// ─────────────────────────────────────────────────────────────
function ScreenAnalyzing() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <button style={iconBtn}><Ic.close /></button>
            <div style={{ flex: 1 }} />
            <BrandTag>Analyzing</BrandTag>
          </div>
        </Pad>

        {/* Product preview card */}
        <Pad style={{ paddingTop: 28 }}>
          <Card style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 16 }}>
            <FoodThumb seed="ChocoGranolaBar" size={72} radius={20} label="🍫" />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.5 }}>Detected</div>
              <div style={{ fontSize: 19, fontWeight: 700, color: COCO.ink, letterSpacing: -0.4, marginTop: 4 }}>Choco Granola Bar</div>
              <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 500, marginTop: 2 }}>Picky · 35g · Barcode 7350045</div>
            </div>
          </Card>
        </Pad>

        {/* Big animated-feeling sparkle */}
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
          <div style={{ position: 'absolute', width: 280, height: 280, borderRadius: '50%', background: 'radial-gradient(circle, #BEF26466 0%, transparent 65%)' }} />
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <CoconutMark size={140} gid="analyzing-mark" />
            <div style={{ position: 'absolute', top: -16, right: -22, color: COCO.amber }}><Ic.sparkle style={{ width: 30, height: 30 }} /></div>
            <div style={{ position: 'absolute', bottom: -8, left: -28, color: COCO.emerald }}><Ic.sparkle style={{ width: 22, height: 22 }} /></div>
            <div style={{ position: 'absolute', top: 38, left: -48, color: COCO.lime }}><Ic.sparkle style={{ width: 14, height: 14 }} /></div>
          </div>
        </div>

        {/* Progress checklist */}
        <Pad style={{ paddingTop: 0, paddingBottom: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 2 }}>Cracking it open</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 12 }}>
            <ProgressStep label="Found the product" done />
            <ProgressStep label="Read 14 ingredients" done />
            <ProgressStep label="Weighing additives" active />
            <ProgressStep label="Scoring for your goals" />
          </div>
        </Pad>

        <div style={{ padding: '24px 20px 16px' }}>
          {/* progress bar */}
          <div style={{ position: 'relative', height: 8, borderRadius: 4, background: 'rgba(26,20,16,0.08)' }}>
            <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '68%', borderRadius: 4, background: COCO.gradient }} />
          </div>
          <div style={{ textAlign: 'center', fontSize: 13, color: COCO.muted, fontWeight: 600, marginTop: 10 }}>about 2 seconds</div>
        </div>
      </div>
    </AndroidDevice>
  );
}
function ProgressStep({ label, done, active }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 15, color: active || done ? COCO.ink : COCO.muted, fontWeight: 600 }}>
      <div style={{
        width: 20, height: 20, borderRadius: 10, flexShrink: 0,
        background: done ? COCO.emerald : (active ? COCO.amber : 'rgba(26,20,16,0.1)'),
        color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {done && <Ic.check style={{ width: 12, height: 12 }} />}
        {active && <div style={{ width: 8, height: 8, borderRadius: 4, background: '#fff' }} />}
      </div>
      {label}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 8 · SEARCH RESULTS
// ─────────────────────────────────────────────────────────────
function ScreenSearch() {
  const results = [
    { name: 'Oatly Barista Edition', sub: 'Oat milk · 1L', s: 82, thumb: 'O' },
    { name: 'Minor Figures Oat', sub: 'Oat milk · 1L', s: 78, thumb: 'M' },
    { name: 'Califia Farms Oat', sub: 'Oat milk · 946ml', s: 71, thumb: 'C' },
    { name: 'Alpro Oat No Sugars', sub: 'Oat milk · 1L', s: 89, thumb: 'A' },
    { name: 'Pacific Original', sub: 'Oat milk · 946ml', s: 64, thumb: 'P' },
    { name: 'Chobani Oat Plain', sub: 'Oat milk · 1.4L', s: 76, thumb: 'C' },
  ];
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
            <button style={iconBtn}><Ic.back /></button>
            <div style={{
              flex: 1, display: 'flex', alignItems: 'center', gap: 10,
              background: '#fff', borderRadius: 999, padding: '10px 16px',
            }}>
              <Ic.search style={{ width: 18, height: 18, color: COCO.muted }} />
              <span style={{ fontSize: 15, fontWeight: 600, color: COCO.ink, flex: 1 }}>oat milk</span>
              <Ic.close style={{ width: 16, height: 16, color: COCO.muted }} />
            </div>
          </div>
          {/* filter chips */}
          <div style={{ display: 'flex', gap: 8, overflow: 'hidden', paddingBottom: 4 }}>
            <Chip color={COCO.ink} ink="#fff">All</Chip>
            <Chip>Crisp 80+</Chip>
            <Chip>Low sugar</Chip>
            <Chip>No seed oils</Chip>
            <Chip>High protein</Chip>
          </div>
          <div style={{ fontSize: 12, color: COCO.muted, fontWeight: 600, marginTop: 16, marginBottom: 6, textTransform: 'uppercase', letterSpacing: 1.5 }}>
            127 matches · sorted by score
          </div>
        </Pad>
        <div style={{ flex: 1, padding: '0 20px 12px', overflowY: 'auto' }}>
          <Card style={{ padding: 6 }}>
            {results.map((r, i) => (
              <React.Fragment key={i}>
                {i > 0 && <Hr m={0} />}
                <FoodRow name={r.name} sub={r.sub} score={r.s} thumb={r.thumb} />
              </React.Fragment>
            ))}
          </Card>
        </div>
        <BottomNav active="scan" />
      </div>
    </AndroidDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// 9 · FOOD DETAIL — LIST BREAKDOWN
// ─────────────────────────────────────────────────────────────
function ScreenDetailList() {
  const score = 42;
  const t = tier(score);
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        {/* top bar */}
        <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <button style={iconBtn}><Ic.back /></button>
          <div style={{ flex: 1 }} />
          <button style={iconBtn}><Ic.heart /></button>
          <button style={iconBtn}><Ic.swap /></button>
        </div>
        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 12 }}>
          {/* hero */}
          <div style={{ padding: '4px 20px 20px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16 }}>
              <FoodThumb seed="ChocoBar" size={88} radius={22} label="🍫" />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.5 }}>Picky</div>
                <div style={{ fontSize: 24, fontWeight: 700, color: COCO.ink, letterSpacing: -0.6, lineHeight: 1.1, marginTop: 4 }}>
                  Choco Granola Bar
                </div>
                <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 500, marginTop: 4 }}>Snack · 35g · 168 kcal</div>
              </div>
            </div>

            {/* score card */}
            <Card style={{ marginTop: 18, background: t.bg, padding: 20, display: 'flex', alignItems: 'center', gap: 16 }}>
              <ScoreRing score={score} size={104} thickness={11} label={false} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 26, fontWeight: 700, color: t.inkOn, letterSpacing: -0.5, lineHeight: 1.05 }}>{t.label}.</div>
                <div style={{ fontSize: 13, color: t.inkOn, opacity: 0.75, fontWeight: 600, marginTop: 4, lineHeight: 1.35 }}>
                  Heavy added sugar and a few additives pull this one down.
                </div>
              </div>
            </Card>
          </div>

          {/* breakdown */}
          <Pad style={{ paddingTop: 0 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: COCO.ink, letterSpacing: -0.3, marginBottom: 10 }}>Why this score</div>
            <Card style={{ padding: 16 }}>
              <Axis label="Nutrition" value={62} note="Whole grain oats help" />
              <Hr />
              <Axis label="Processing" value={38} note="Mildly ultra-processed" />
              <Hr />
              <Axis label="Added sugar" value={22} note="11g per bar — high" bad />
              <Hr />
              <Axis label="Additives" value={48} note="Soy lecithin, natural flavors" />
            </Card>
          </Pad>

          {/* flags */}
          <Pad style={{ paddingTop: 18 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: COCO.ink, letterSpacing: -0.3, marginBottom: 10 }}>Worth flagging</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <Flag color={COCO.red} icon={<Ic.warn />} title="High added sugar" sub="11g — about 22% DV" />
              <Flag color={COCO.amber} icon={<Ic.warn />} title="Sunflower oil" sub="Moderate seed-oil content" />
              <Flag color={COCO.emerald} icon={<Ic.check />} title="No artificial colors" sub="Clean on dyes" />
            </div>
          </Pad>

          {/* swap teaser */}
          <Pad style={{ paddingTop: 18, paddingBottom: 16 }}>
            <Card style={{ background: COCO.ink, color: '#fff', padding: 18, display: 'flex', alignItems: 'center', gap: 14 }}>
              <FoodThumb seed="RXBar" size={48} radius={14} label="R" />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: COCO.lime, textTransform: 'uppercase', letterSpacing: 1.5 }}>Better swap</div>
                <div style={{ fontSize: 15, fontWeight: 700, color: '#fff', marginTop: 2 }}>RXBAR Chocolate Sea Salt</div>
                <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontWeight: 500, marginTop: 2 }}>+39 score · 12g protein</div>
              </div>
              <ScoreChip score={81} />
            </Card>
          </Pad>
        </div>
      </div>
    </AndroidDevice>
  );
}
function Axis({ label, value, note, bad }) {
  const t = tier(value);
  return (
    <div style={{ padding: '10px 4px' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
        <div style={{ fontSize: 14, fontWeight: 700, color: COCO.ink }}>{label}</div>
        <div style={{ fontSize: 13, fontWeight: 700, color: bad ? COCO.red : t.color, fontVariantNumeric: 'tabular-nums' }}>{value}</div>
      </div>
      <div style={{ height: 8, borderRadius: 4, background: 'rgba(26,20,16,0.06)', position: 'relative' }}>
        <div style={{ position: 'absolute', inset: 0, width: `${value}%`, background: bad ? COCO.red : t.color, borderRadius: 4 }} />
      </div>
      <div style={{ fontSize: 12, color: COCO.muted, fontWeight: 500, marginTop: 6 }}>{note}</div>
    </div>
  );
}
function Flag({ color, icon, title, sub }) {
  return (
    <Card style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ width: 36, height: 36, borderRadius: 18, background: color, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        {React.cloneElement(icon, { width: 18, height: 18 })}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 700, color: COCO.ink, letterSpacing: -0.2 }}>{title}</div>
        <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 500, marginTop: 1 }}>{sub}</div>
      </div>
    </Card>
  );
}

// ─────────────────────────────────────────────────────────────
// 10 · FOOD DETAIL — VISUAL / AXES VARIANT
// ─────────────────────────────────────────────────────────────
function ScreenDetailAxes() {
  const score = 78;
  const t = tier(score);
  // 5-axis values for a pentagon
  const axes = [
    { k: 'Nutri', v: 84 },
    { k: 'Whole', v: 72 },
    { k: 'Sugar', v: 88 }, // higher = less sugar / better
    { k: 'Clean', v: 64 },
    { k: 'Protein', v: 80 },
  ];
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <button style={iconBtn}><Ic.back /></button>
          <div style={{ flex: 1 }} />
          <button style={iconBtn}><Ic.heart /></button>
          <button style={iconBtn}><Ic.swap /></button>
        </div>

        {/* big score hero */}
        <div style={{ padding: '0 20px 12px' }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.5 }}>Oatly · Oat milk</div>
          <div style={{ fontSize: 30, fontWeight: 700, color: COCO.ink, letterSpacing: -1, lineHeight: 1.02, marginTop: 4 }}>
            Barista Edition<br/>1L carton
          </div>
        </div>

        {/* score + radar */}
        <div style={{ position: 'relative', margin: '6px 20px 0', background: '#fff', borderRadius: 28, padding: 22, overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 180, height: 180, borderRadius: '50%', background: COCO.gradient, opacity: 0.18 }} />
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 18 }}>
            <div>
              <div style={{ fontSize: 100, fontWeight: 700, lineHeight: 0.9, letterSpacing: -5, color: COCO.ink, fontVariantNumeric: 'tabular-nums' }}>{score}</div>
              <div style={{ fontSize: 14, fontWeight: 700, color: t.color, textTransform: 'uppercase', letterSpacing: 2, marginTop: 4 }}>{t.label}</div>
            </div>
            <Radar axes={axes} size={170} />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 16, paddingTop: 16 }}>
          {/* mini axes legend */}
          <Pad style={{ paddingTop: 0 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {axes.map((a) => {
                const tt = tier(a.v);
                return (
                  <div key={a.k} style={{ background: '#fff', borderRadius: 16, padding: '12px 14px' }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                      <div style={{ fontSize: 13, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.4 }}>{a.k}</div>
                      <div style={{ fontSize: 18, fontWeight: 700, color: tt.color, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.5 }}>{a.v}</div>
                    </div>
                    <div style={{ height: 4, borderRadius: 2, background: 'rgba(26,20,16,0.06)', marginTop: 6 }}>
                      <div style={{ height: 4, width: `${a.v}%`, borderRadius: 2, background: tt.color }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </Pad>

          {/* highlights */}
          <Pad style={{ paddingTop: 18 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: COCO.ink, letterSpacing: -0.3, marginBottom: 10 }}>Highlights</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <Flag color={COCO.emerald} icon={<Ic.check />} title="No added sugar" sub="Naturally sweet from oats" />
              <Flag color={COCO.emerald} icon={<Ic.check />} title="Fortified" sub="Calcium + B12 + D" />
              <Flag color={COCO.amber} icon={<Ic.warn />} title="Contains rapeseed oil" sub="2% — minor seed-oil hit" />
            </div>
          </Pad>
        </div>
      </div>
    </AndroidDevice>
  );
}

// Radar / pentagon chart
function Radar({ axes, size = 180 }) {
  const cx = size / 2, cy = size / 2;
  const r = size / 2 - 14;
  const n = axes.length;
  const pt = (i, t) => {
    const a = -Math.PI / 2 + (i * 2 * Math.PI) / n;
    return [cx + Math.cos(a) * r * t, cy + Math.sin(a) * r * t];
  };
  const grid = [0.25, 0.5, 0.75, 1];
  const dataPath = axes.map((ax, i) => {
    const [x, y] = pt(i, ax.v / 100);
    return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ') + 'Z';
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {grid.map((g, gi) => (
        <polygon key={gi} fill="none" stroke="rgba(26,20,16,0.08)" strokeWidth="1"
          points={axes.map((_, i) => pt(i, g).map(v => v.toFixed(1)).join(',')).join(' ')} />
      ))}
      {axes.map((_, i) => {
        const [x, y] = pt(i, 1);
        return <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke="rgba(26,20,16,0.08)" strokeWidth="1" />;
      })}
      <path d={dataPath} fill={COCO.emerald} fillOpacity="0.18" stroke={COCO.emerald} strokeWidth="2.5" strokeLinejoin="round" />
      {axes.map((ax, i) => {
        const [x, y] = pt(i, ax.v / 100);
        return <circle key={i} cx={x} cy={y} r="3.5" fill="#fff" stroke={COCO.emerald} strokeWidth="2" />;
      })}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 11 · SWAP CARD — side-by-side
// ─────────────────────────────────────────────────────────────
function ScreenSwapCard() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <button style={iconBtn}><Ic.back /></button>
          <div style={{ flex: 1, fontSize: 17, fontWeight: 700, color: COCO.ink }}>Better swap</div>
          <button style={iconBtn}><Ic.close /></button>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 20 }}>
          <Pad style={{ paddingTop: 6 }}>
            <BrandTag>+39 better</BrandTag>
            <div style={{ fontSize: 34, fontWeight: 700, color: COCO.ink, letterSpacing: -1.2, lineHeight: 1.02, marginTop: 12 }}>
              Try <span style={{ color: COCO.emeraldDeep }}>RXBAR</span><br/>instead of Picky.
            </div>
            <div style={{ fontSize: 14, color: COCO.muted, fontWeight: 500, marginTop: 8, lineHeight: 1.4 }}>
              Same chocolate snack feel, but cleaner ingredients and 3× the protein.
            </div>
          </Pad>

          {/* vs cards */}
          <Pad style={{ paddingTop: 22 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'stretch', gap: 8 }}>
              <SwapCol name="Picky" sub="Choco granola bar" score={42} thumb="P" dim />
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <div style={{ width: 36, height: 36, borderRadius: 18, background: COCO.ink, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Ic.arrow style={{ width: 18, height: 18 }} />
                </div>
              </div>
              <SwapCol name="RXBAR" sub="Choco Sea Salt" score={81} thumb="R" winner />
            </div>
          </Pad>

          {/* why */}
          <Pad style={{ paddingTop: 22 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: COCO.ink, letterSpacing: -0.3, marginBottom: 12 }}>What changes</div>
            <Card style={{ padding: 0 }}>
              <DeltaRow label="Added sugar" from="11g" to="3g" good />
              <Hr m={0} />
              <DeltaRow label="Protein" from="3g" to="12g" good />
              <Hr m={0} />
              <DeltaRow label="Ingredients" from="14" to="6" good />
              <Hr m={0} />
              <DeltaRow label="Calories" from="168" to="210" />
            </Card>
          </Pad>

          <Pad style={{ paddingTop: 18 }}>
            <Pill kind="brand" size="lg" full>Save for next shop <Ic.heart /></Pill>
            <Pill kind="ghost" size="md" full style={{ marginTop: 10 }}>See 4 more swaps</Pill>
          </Pad>
        </div>
      </div>
    </AndroidDevice>
  );
}
function SwapCol({ name, sub, score, thumb, dim, winner }) {
  const t = tier(score);
  return (
    <div style={{
      background: winner ? '#fff' : COCO.cream2,
      borderRadius: 22, padding: 14,
      opacity: dim ? 0.72 : 1,
      border: winner ? `2px solid ${COCO.emerald}` : 'none',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
    }}>
      <FoodThumb seed={thumb} label={thumb} size={64} radius={18} />
      <div style={{ fontSize: 14, fontWeight: 700, color: COCO.ink, textAlign: 'center', letterSpacing: -0.2 }}>{name}</div>
      <div style={{ fontSize: 11, color: COCO.muted, fontWeight: 500, textAlign: 'center', minHeight: 14 }}>{sub}</div>
      <div style={{ fontSize: 32, fontWeight: 700, color: t.color, letterSpacing: -1.2, fontVariantNumeric: 'tabular-nums', lineHeight: 1 }}>{score}</div>
    </div>
  );
}
function DeltaRow({ label, from, to, good }) {
  return (
    <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 700, color: COCO.ink }}>{label}</div>
      <div style={{ fontSize: 14, fontWeight: 600, color: COCO.muted, textDecoration: 'line-through' }}>{from}</div>
      <Ic.arrow style={{ width: 14, height: 14, color: COCO.muted }} />
      <div style={{ fontSize: 14, fontWeight: 700, color: good ? COCO.emerald : COCO.ink }}>{to}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 12 · SWAP BROWSE — list of better picks for a category
// ─────────────────────────────────────────────────────────────
function ScreenSwapBrowse() {
  const swaps = [
    { name: 'Surreal Frosted', sub: 'Cereal · 240g', s: 86, delta: 38, thumb: 'S' },
    { name: 'Three Wishes Honey', sub: 'Cereal · 240g', s: 84, delta: 36, thumb: 'T' },
    { name: 'Magic Spoon Cocoa', sub: 'Cereal · 210g', s: 79, delta: 31, thumb: 'M' },
    { name: 'Catalina Crunch', sub: 'Cereal · 255g', s: 76, delta: 28, thumb: 'C' },
    { name: 'Kashi GO Lean', sub: 'Cereal · 380g', s: 71, delta: 23, thumb: 'K' },
  ];
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
            <button style={iconBtn}><Ic.back /></button>
            <div style={{ flex: 1 }} />
            <button style={iconBtn}><Ic.search /></button>
          </div>

          <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.5 }}>Swaps for</div>
          <div style={{ fontSize: 32, fontWeight: 700, color: COCO.ink, letterSpacing: -1, lineHeight: 1.02, marginTop: 4 }}>
            Sugary cereal
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12 }}>
            <FoodThumb seed="LuckyCharms" label="L" size={36} radius={10} />
            <div style={{ fontSize: 13, color: COCO.muted, fontWeight: 600 }}>You currently buy <span style={{ color: COCO.red, fontWeight: 700 }}>Lucky Charms</span> · score 31</div>
          </div>

          {/* sort chips */}
          <div style={{ display: 'flex', gap: 8, marginTop: 18, overflow: 'hidden' }}>
            <Chip color={COCO.ink} ink="#fff">Best score</Chip>
            <Chip>Lowest sugar</Chip>
            <Chip>Highest protein</Chip>
            <Chip>Whole grain</Chip>
          </div>
        </Pad>

        <div style={{ flex: 1, overflowY: 'auto', padding: '14px 20px 12px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {swaps.map((s, i) => (
              <Card key={i} style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
                <FoodThumb seed={s.thumb} label={s.thumb} size={52} radius={14} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 15, fontWeight: 700, color: COCO.ink, letterSpacing: -0.2 }}>{s.name}</div>
                  <div style={{ fontSize: 12, color: COCO.muted, fontWeight: 500, marginTop: 1 }}>{s.sub}</div>
                  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, marginTop: 6, background: 'rgba(16,185,129,0.12)', color: COCO.emeraldDeep, fontSize: 11, fontWeight: 700, padding: '2px 8px', borderRadius: 999 }}>
                    +{s.delta} score
                  </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
                  <ScoreChip score={s.s} big />
                  <button style={{
                    width: 32, height: 32, borderRadius: 16, border: 'none',
                    background: COCO.ink, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}><Ic.plus style={{ width: 16, height: 16 }} /></button>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </AndroidDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// 13 · FRIENDS FEED
// ─────────────────────────────────────────────────────────────
function ScreenFeed() {
  return (
    <AndroidDevice width={PHONE_W} height={PHONE_H}>
      <div style={{ height: '100%', background: COCO.cream, display: 'flex', flexDirection: 'column' }}>
        <Pad style={{ paddingTop: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
            <div style={{ flex: 1, fontSize: 28, fontWeight: 700, color: COCO.ink, letterSpacing: -0.8 }}>Friends</div>
            <button style={iconBtn}><Ic.search /></button>
            <button style={iconBtn}><Ic.plus /></button>
          </div>
        </Pad>

        {/* avatars row */}
        <div style={{ padding: '0 0 8px', overflow: 'hidden' }}>
          <div style={{ display: 'flex', gap: 14, padding: '0 20px' }}>
            <AvatarStory name="You" rank="78" me />
            <AvatarStory name="Mia" rank="91" />
            <AvatarStory name="Jay" rank="72" />
            <AvatarStory name="Ren" rank="84" />
            <AvatarStory name="Sam" rank="59" />
            <AvatarStory name="Ana" rank="88" />
          </div>
        </div>

        {/* leaderboard widget */}
        <Pad style={{ paddingTop: 12 }}>
          <Card style={{ padding: 16, background: COCO.ink, color: '#fff' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <Ic.flame style={{ color: COCO.coral }} />
              <div style={{ flex: 1, fontSize: 15, fontWeight: 700 }}>Weekly streak race</div>
              <div style={{ fontSize: 12, fontWeight: 600, color: 'rgba(255,255,255,0.55)' }}>4 days left</div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <RaceRow rank="1" name="Mia" score={91} pct={0.96} />
              <RaceRow rank="2" name="Ren" score={84} pct={0.88} />
              <RaceRow rank="3" name="You" score={78} pct={0.82} me />
              <RaceRow rank="4" name="Jay" score={72} pct={0.75} />
            </div>
          </Card>
        </Pad>

        <div style={{ flex: 1, overflowY: 'auto', padding: '14px 20px 12px' }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: COCO.muted, textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 10 }}>Activity</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <FeedPost name="Mia" time="12m" verb="scanned" item="Skyr blueberry" score={88} thumb="S" reactions={['🥥','🔥']} caption="snack mvp" />
            <FeedPost name="Jay" time="38m" verb="swapped" item="Lucky Charms → Surreal" score={86} thumb="S" reactions={['🥥']} delta="+55" />
            <FeedPost name="Ren" time="1h" verb="hit" item="14-day streak" badge thumb="R" reactions={['🔥','🔥','🥥']} />
          </div>
        </div>

        <BottomNav active="feed" />
      </div>
    </AndroidDevice>
  );
}
function AvatarStory({ name, rank, me }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, width: 60, flexShrink: 0 }}>
      <div style={{
        padding: 2.5, borderRadius: 36, background: me ? COCO.ink : COCO.gradient, position: 'relative',
      }}>
        <div style={{ background: COCO.cream, borderRadius: 34, padding: 2 }}>
          <Avatar name={name} size={48} hueShift={me ? 0 : name.charCodeAt(0) * 11} />
        </div>
        <div style={{
          position: 'absolute', bottom: -4, right: -4,
          background: '#fff', color: COCO.ink,
          fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 999,
          border: `2px solid ${COCO.cream}`, fontVariantNumeric: 'tabular-nums',
        }}>{rank}</div>
      </div>
      <div style={{ fontSize: 12, fontWeight: 700, color: COCO.ink }}>{name}</div>
    </div>
  );
}
function RaceRow({ rank, name, score, pct, me }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: 'rgba(255,255,255,0.55)', width: 14, fontVariantNumeric: 'tabular-nums' }}>{rank}</div>
      <Avatar name={name} size={26} />
      <div style={{ fontSize: 13, fontWeight: 700, color: me ? COCO.lime : '#fff', minWidth: 38 }}>{name}{me && ' ·'}</div>
      <div style={{ flex: 1, height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.08)', position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', inset: 0, width: `${pct * 100}%`, background: me ? COCO.gradient : 'rgba(255,255,255,0.5)', borderRadius: 3 }} />
      </div>
      <div style={{ fontSize: 13, fontWeight: 700, color: '#fff', fontVariantNumeric: 'tabular-nums', width: 24, textAlign: 'right' }}>{score}</div>
    </div>
  );
}
function FeedPost({ name, time, verb, item, score, thumb, reactions, caption, delta, badge }) {
  return (
    <Card style={{ padding: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <Avatar name={name} size={36} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, color: COCO.ink, lineHeight: 1.3 }}>
            <span style={{ fontWeight: 700 }}>{name}</span>
            <span style={{ color: COCO.muted, fontWeight: 500 }}> {verb} </span>
            <span style={{ fontWeight: 700 }}>{item}</span>
          </div>
          <div style={{ fontSize: 11, color: COCO.muted, fontWeight: 600, marginTop: 1 }}>{time} ago</div>
        </div>
        {score !== undefined && <ScoreChip score={score} />}
        {badge && <div style={{ background: COCO.gradient, color: COCO.brownDeep, fontSize: 11, fontWeight: 700, padding: '4px 10px', borderRadius: 999 }}>STREAK</div>}
      </div>
      {(caption || delta) && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 10, paddingLeft: 46 }}>
          <FoodThumb seed={thumb} label={thumb} size={36} radius={10} />
          <div style={{ flex: 1, fontSize: 13, color: COCO.ink2, fontWeight: 600, fontStyle: caption ? 'italic' : 'normal' }}>
            {caption || `${delta} score improvement`}
          </div>
        </div>
      )}
      {reactions && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 12, paddingLeft: 46 }}>
          {reactions.map((r, i) => (
            <span key={i} style={{ background: COCO.cream2, fontSize: 13, padding: '4px 9px', borderRadius: 999, fontWeight: 600 }}>{r}</span>
          ))}
          <span style={{ background: 'rgba(26,20,16,0.06)', fontSize: 13, padding: '4px 9px', borderRadius: 999, color: COCO.muted, fontWeight: 600 }}>+</span>
        </div>
      )}
    </Card>
  );
}

Object.assign(window, {
  ScreenScanCamera, ScreenAnalyzing, ScreenSearch,
  ScreenDetailList, ScreenDetailAxes,
  ScreenSwapCard, ScreenSwapBrowse, ScreenFeed,
});
