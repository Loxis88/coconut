// coconut-ui.jsx — Shared atoms for the Coconut app
// Brand, score tiers, icons, common chips/cards/buttons.

const COCO = {
  cream: '#FFF6E8',
  cream2: '#FBEFD9',
  ink: '#1A1410',
  ink2: '#3D332B',
  muted: '#7A6B5C',
  hairline: 'rgba(26,20,16,0.08)',
  white: '#FFFFFF',
  lime: '#BEF264',
  emerald: '#10B981',
  emeraldDeep: '#047857',
  amber: '#F59E0B',
  coral: '#F97316',
  red: '#E11D48',
  brown: '#8B5A2B',
  brownDeep: '#3F2412',
  gradient: 'linear-gradient(135deg, #BEF264 0%, #10B981 75%, #047857 100%)',
  gradientWarm: 'linear-gradient(135deg, #FDE68A 0%, #F97316 100%)',
};

// 0-100 -> tier {key,label,color,bg,inkOnColor}
function tier(score) {
  if (score >= 80) return { key: 'crisp', label: 'Crisp',  color: COCO.emerald, bg: '#D7F5E6', inkOn: '#04432A' };
  if (score >= 60) return { key: 'solid', label: 'Solid',  color: '#A3B91D',    bg: '#F0F6CF', inkOn: '#3A4407' };
  if (score >= 40) return { key: 'iffy',  label: 'Iffy',   color: COCO.coral,   bg: '#FFE2CC', inkOn: '#5A1F00' };
  return                  { key: 'skip',  label: 'Skip',   color: COCO.red,     bg: '#FFD9DF', inkOn: '#5C0716' };
}

// ─────────────────────────────────────────────────────────────
// Coconut mark — three-eye coconut on the brand gradient
// ─────────────────────────────────────────────────────────────
function CoconutMark({ size = 32, gid }) {
  const id = gid || `coco-g-${size}`;
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" style={{ display: 'block' }}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#BEF264" />
          <stop offset="0.7" stopColor="#10B981" />
          <stop offset="1" stopColor="#047857" />
        </linearGradient>
      </defs>
      <circle cx="16" cy="16" r="15" fill={`url(#${id})`} />
      <ellipse cx="11" cy="13.5" rx="1.6" ry="2.2" fill={COCO.ink} />
      <ellipse cx="20.5" cy="13.5" rx="1.6" ry="2.2" fill={COCO.ink} />
      <ellipse cx="15.8" cy="21" rx="1.6" ry="2.2" fill={COCO.ink} />
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Icons (24px stroke, inline SVG). Keep these tiny + consistent.
// ─────────────────────────────────────────────────────────────
const Ic = {
  scan: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2"/>
      <path d="M3 12h18"/>
    </svg>
  ),
  camera: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M4 7h3l2-2h6l2 2h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z"/>
      <circle cx="12" cy="13" r="3.5"/>
    </svg>
  ),
  search: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <circle cx="11" cy="11" r="7"/><path d="M21 21l-4.5-4.5"/>
    </svg>
  ),
  flash: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" {...p}>
      <path d="M13 2L4 14h6l-1 8 9-12h-6l1-8z"/>
    </svg>
  ),
  swap: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M7 4l-4 4 4 4M3 8h14M17 20l4-4-4-4M21 16H7"/>
    </svg>
  ),
  heart: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M20.4 12.3l-7.7 7.6a1 1 0 0 1-1.4 0L3.6 12.3a5 5 0 0 1 7.1-7.1L12 6.5l1.3-1.3a5 5 0 0 1 7.1 7.1z"/>
    </svg>
  ),
  flame: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" {...p}>
      <path d="M13 2c.5 5-4 6-4 11a5 5 0 0 0 10 0c0-2.5-2-3.5-2-5.5C17 5 13.5 4.5 13 2zm-4.5 9.5c-.3 1-.5 2-.5 3a4 4 0 0 0 4 4c-2 0-3.5-1.5-3.5-3.5 0-1.3.5-2.4 0-3.5z"/>
    </svg>
  ),
  bell: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M6 8a6 6 0 1 1 12 0c0 7 3 8 3 8H3s3-1 3-8M10 21a2 2 0 0 0 4 0"/>
    </svg>
  ),
  plus: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" {...p}>
      <path d="M12 5v14M5 12h14"/>
    </svg>
  ),
  arrow: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M5 12h14M13 5l7 7-7 7"/>
    </svg>
  ),
  back: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M19 12H5M12 19l-7-7 7-7"/>
    </svg>
  ),
  close: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" {...p}>
      <path d="M18 6L6 18M6 6l12 12"/>
    </svg>
  ),
  home: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M3 11l9-8 9 8v10a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1z"/>
    </svg>
  ),
  log: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8 9h8M8 13h8M8 17h5"/>
    </svg>
  ),
  feed: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <circle cx="9" cy="8" r="3"/><circle cx="17" cy="10" r="2.5"/>
      <path d="M3 19c.5-3 3-5 6-5s5.5 2 6 5M14 19c.4-2 2-3 3.5-3s3.1 1 3.5 3"/>
    </svg>
  ),
  me: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <circle cx="12" cy="9" r="4"/><path d="M4 20c1-4 4.5-6 8-6s7 2 8 6"/>
    </svg>
  ),
  sparkle: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" {...p}>
      <path d="M12 2l1.7 5.6L19 9l-5.3 1.4L12 16l-1.7-5.6L5 9l5.3-1.4L12 2zm7 11l.9 2.6 2.6 1-2.6.7-.9 2.7-.9-2.7-2.6-.7 2.6-1L19 13z"/>
    </svg>
  ),
  check: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M5 12.5L10 17.5 20 6.5"/>
    </svg>
  ),
  warn: (p) => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...p}>
      <path d="M12 9v4M12 17h.01"/><path d="M10.3 3.7L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.7a2 2 0 0 0-3.4 0z"/>
    </svg>
  ),
  dot: (p) => <svg width="6" height="6" viewBox="0 0 6 6" {...p}><circle cx="3" cy="3" r="3" fill="currentColor"/></svg>,
};

// ─────────────────────────────────────────────────────────────
// Score ring — big circular gauge
// ─────────────────────────────────────────────────────────────
function ScoreRing({ score, size = 160, thickness = 14, label }) {
  const t = tier(score);
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - score / 100);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={COCO.hairline} strokeWidth={thickness} fill="none" />
        <circle cx={size/2} cy={size/2} r={r} stroke={t.color} strokeWidth={thickness} fill="none"
          strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off} />
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', lineHeight: 1,
      }}>
        <div style={{ fontSize: size * 0.42, fontWeight: 700, color: COCO.ink, fontVariantNumeric: 'tabular-nums', letterSpacing: -2 }}>{score}</div>
        {label !== false && (
          <div style={{ fontSize: size * 0.1, fontWeight: 600, color: t.color, textTransform: 'uppercase', letterSpacing: 2, marginTop: 4 }}>{t.label}</div>
        )}
      </div>
    </div>
  );
}

// Compact pill score chip
function ScoreChip({ score, big = false }) {
  const t = tier(score);
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: t.color, color: '#fff',
      borderRadius: 999, padding: big ? '8px 14px' : '4px 10px',
      fontSize: big ? 18 : 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
    }}>
      {score}<span style={{ opacity: .8, fontSize: big ? 12 : 10, fontWeight: 600 }}>/100</span>
    </div>
  );
}

// Square food thumb — abstract product art, no real photos.
// Uses a hash of `seed` to pick a tasteful color + label glyph.
function FoodThumb({ seed = 'x', size = 56, label, radius = 16, dark }) {
  const palettes = [
    ['#FFE4B5', '#F97316'], // peach + orange (cereal)
    ['#D9F99D', '#65A30D'], // lime + green (greens)
    ['#FECACA', '#DC2626'], // pink + red (meat)
    ['#FED7AA', '#C2410C'], // tan + rust (bread)
    ['#E0F2FE', '#0284C7'], // ice + blue (drink)
    ['#FAE8FF', '#A21CAF'], // lilac + magenta (berry)
    ['#FEF3C7', '#A16207'], // cream + ochre (oat)
    ['#DCFCE7', '#15803D'], // mint + forest (veg)
  ];
  let h = 0; for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  const [bg, fg] = palettes[h % palettes.length];
  const glyph = label || seed.slice(0, 1).toUpperCase();
  return (
    <div style={{
      width: size, height: size, borderRadius: radius, background: bg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0, position: 'relative', overflow: 'hidden',
    }}>
      {/* soft swoosh */}
      <div style={{ position: 'absolute', inset: 0, background: `radial-gradient(circle at 30% 25%, rgba(255,255,255,0.7), transparent 55%)` }} />
      <div style={{ position: 'relative', fontSize: size * 0.38, fontWeight: 700, color: fg, letterSpacing: -0.5 }}>{glyph}</div>
    </div>
  );
}

// Avatar — initial in a colored disc
function Avatar({ name = 'Z', size = 36, hueShift = 0 }) {
  let h = 0; for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  const hue = (h + hueShift) % 360;
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: `linear-gradient(135deg, hsl(${hue} 70% 75%), hsl(${(hue+30)%360} 65% 55%))`,
      color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.42, fontWeight: 700, flexShrink: 0,
    }}>{name.slice(0, 1).toUpperCase()}</div>
  );
}

// Generic pill button
function Pill({ children, kind = 'ink', size = 'md', style, full }) {
  const sizes = { sm: { p: '6px 12px', f: 13 }, md: { p: '10px 18px', f: 15 }, lg: { p: '16px 24px', f: 17 } };
  const kinds = {
    ink:     { bg: COCO.ink, color: '#fff', border: 'none' },
    cream:   { bg: COCO.cream2, color: COCO.ink, border: 'none' },
    outline: { bg: 'transparent', color: COCO.ink, border: `1.5px solid ${COCO.ink}` },
    brand:   { bg: COCO.gradient, color: COCO.brownDeep, border: 'none' },
    white:   { bg: '#fff', color: COCO.ink, border: 'none' },
    ghost:   { bg: 'rgba(26,20,16,0.06)', color: COCO.ink, border: 'none' },
  };
  const s = sizes[size], k = kinds[kind];
  return (
    <button style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      borderRadius: 999, padding: s.p, fontSize: s.f, fontWeight: 700,
      fontFamily: 'inherit', cursor: 'pointer',
      width: full ? '100%' : undefined,
      ...k, ...style,
    }}>{children}</button>
  );
}

// Section card — rounded, with cream surface
function Card({ children, style, bg = '#fff' }) {
  return (
    <div style={{ background: bg, borderRadius: 24, padding: 18, ...style }}>{children}</div>
  );
}

// Small label/chip
function Chip({ children, color = COCO.cream2, ink = COCO.ink, small }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      background: color, color: ink, borderRadius: 999,
      padding: small ? '2px 8px' : '4px 10px',
      fontSize: small ? 11 : 12, fontWeight: 600, lineHeight: 1.2,
    }}>{children}</span>
  );
}

// Bottom nav for the app
function BottomNav({ active = 'home' }) {
  const items = [
    ['home', 'Home', Ic.home],
    ['log', 'Log', Ic.log],
    ['scan', 'Scan', null], // big FAB-ish center
    ['feed', 'Friends', Ic.feed],
    ['me', 'You', Ic.me],
  ];
  return (
    <div style={{
      background: '#fff',
      paddingTop: 8, paddingBottom: 6,
      display: 'grid', gridTemplateColumns: '1fr 1fr 1.2fr 1fr 1fr',
      alignItems: 'center', justifyItems: 'center',
      borderTop: `1px solid ${COCO.hairline}`,
    }}>
      {items.map(([key, label, Icon]) => {
        if (key === 'scan') {
          return (
            <div key={key} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, transform: 'translateY(-12px)' }}>
              <div style={{
                width: 56, height: 56, borderRadius: 28,
                background: COCO.gradient,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 8px 20px rgba(16,185,129,0.35)',
                color: COCO.brownDeep,
              }}>
                <Ic.scan />
              </div>
              <div style={{ fontSize: 11, fontWeight: 700, color: COCO.ink }}>Scan</div>
            </div>
          );
        }
        const isActive = key === active;
        return (
          <div key={key} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
            color: isActive ? COCO.ink : COCO.muted,
          }}>
            <Icon />
            <div style={{ fontSize: 11, fontWeight: isActive ? 700 : 500 }}>{label}</div>
          </div>
        );
      })}
    </div>
  );
}

// Animated-looking gradient tag
function BrandTag({ children, style }) {
  return (
    <div style={{
      display: 'inline-block', padding: '4px 12px', borderRadius: 999,
      background: COCO.gradient, color: COCO.brownDeep,
      fontSize: 12, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
      ...style,
    }}>{children}</div>
  );
}

// Slim divider
function Hr({ m = 12 }) {
  return <div style={{ height: 1, background: COCO.hairline, margin: `${m}px 0` }} />;
}

Object.assign(window, {
  COCO, tier, CoconutMark, Ic, ScoreRing, ScoreChip, FoodThumb, Avatar,
  Pill, Card, Chip, BottomNav, BrandTag, Hr,
});
