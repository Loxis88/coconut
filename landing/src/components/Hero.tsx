import { Apple, Play } from 'lucide-react'

function ScoreRing({
  score,
  size = 96,
  stroke = 7,
  color,
}: {
  score: number
  size?: number
  stroke?: number
  color: string
}) {
  const r = (size - stroke) / 2
  const circ = 2 * Math.PI * r
  const offset = circ - (score / 100) * circ
  const label = score >= 80 ? 'Отлично' : score >= 60 ? 'Хорошо' : score >= 40 ? 'Спорно' : 'Плохо'
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#DDD8CB" strokeWidth={stroke} />
        <circle
          cx={size / 2} cy={size / 2} r={r}
          fill="none" stroke={color} strokeWidth={stroke}
          strokeDasharray={circ} strokeDashoffset={offset}
          strokeLinecap="round"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          style={{ transition: 'stroke-dashoffset 1s ease' }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-2xl font-black leading-none" style={{ color }}>{score}</span>
        <span className="text-[9px] font-mono mt-0.5" style={{ color }}>{label}</span>
      </div>
    </div>
  )
}

function PhoneMockup() {
  return (
    <div className="relative select-none">
      {/* Glow behind phone */}
      <div
        className="absolute inset-0 rounded-[40px] blur-3xl"
        style={{ background: 'radial-gradient(ellipse, rgba(21,57,24,0.12) 0%, transparent 70%)', transform: 'scale(0.85) translateY(12%)' }}
      />

      {/* Floating score badges */}
      <div className="absolute -right-10 top-12 bg-card rounded-2xl px-3 py-2 shadow-lg border border-fg/5 text-xs font-mono text-score-excellent animate-bounce" style={{ animationDuration: '3s' }}>
        87 · Отлично
      </div>
      <div className="absolute -left-10 bottom-24 bg-card rounded-2xl px-3 py-2 shadow-lg border border-fg/5 text-xs font-mono text-score-poor" style={{ animation: 'bounce 4s infinite 0.5s' }}>
        28 · Плохо
      </div>

      {/* Phone frame */}
      <div className="relative w-56 h-[480px] bg-bg rounded-[40px] border-2 border-fg/10 shadow-2xl overflow-hidden">
        {/* Notch */}
        <div className="absolute top-0 left-0 right-0 h-8 flex items-center justify-between px-5 pt-1.5">
          <span className="text-[9px] text-fg/30 font-mono">9:41</span>
          <div className="w-16 h-4 bg-fg/8 rounded-b-2xl" />
          <div className="w-4 h-2.5 rounded-sm bg-fg/20" />
        </div>

        {/* Screen content */}
        <div className="pt-8 h-full flex flex-col">
          {/* Back nav */}
          <div className="px-4 py-2 flex items-center gap-1.5">
            <span className="text-[10px] text-primary font-medium">← Сканер</span>
          </div>

          {/* Product header */}
          <div className="px-4 pb-3">
            <p className="text-[10px] text-muted-fg font-mono mb-0.5">Олайс</p>
            <p className="text-[14px] font-bold text-fg leading-tight">Греческий йогурт 2%</p>
            <p className="text-[10px] text-muted-fg font-mono">150 г · Молочные</p>
          </div>

          {/* Score */}
          <div className="flex justify-center py-3">
            <ScoreRing score={87} size={90} stroke={6} color="#1E6B28" />
          </div>

          {/* Nutrition grid */}
          <div className="px-4 pb-3">
            <div className="grid grid-cols-3 gap-1.5">
              {[
                { v: '9г', l: 'Белок' },
                { v: '97', l: 'ккал' },
                { v: '3.5г', l: 'Жиры' },
              ].map(({ v, l }) => (
                <div key={l} className="bg-card rounded-xl p-2 text-center">
                  <div className="text-[12px] font-bold text-fg">{v}</div>
                  <div className="text-[9px] text-muted-fg font-mono">{l}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Positives */}
          <div className="px-4 space-y-1.5">
            {['Живые пробиотики', 'Без добавленного сахара', 'Натуральный состав'].map(item => (
              <div key={item} className="flex items-center gap-2">
                <div className="w-4 h-4 rounded-full bg-score-excellent/15 flex items-center justify-center flex-shrink-0">
                  <span className="text-[8px] text-score-excellent font-bold">✓</span>
                </div>
                <span className="text-[10px] text-fg">{item}</span>
              </div>
            ))}
          </div>

          {/* Bottom bar */}
          <div className="mt-auto px-4 py-3 border-t border-fg/5 flex justify-around">
            {['🏠', '🔍', '📷', '📖', '👤'].map((icon, i) => (
              <span key={i} className="text-base opacity-40">{icon}</span>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function StoreButton({ store }: { store: 'apple' | 'google' }) {
  return (
    <a
      href="#download"
      className="inline-flex items-center gap-3 bg-fg text-bg px-5 py-3.5 rounded-2xl hover:bg-primary transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg group"
    >
      {store === 'apple' ? (
        <Apple size={22} className="flex-shrink-0" />
      ) : (
        <Play size={20} className="flex-shrink-0 fill-bg" />
      )}
      <div className="text-left">
        <div className="text-[10px] opacity-60 leading-none mb-0.5">
          {store === 'apple' ? 'Скачать в' : 'Доступно в'}
        </div>
        <div className="text-sm font-semibold leading-none">
          {store === 'apple' ? 'App Store' : 'Google Play'}
        </div>
      </div>
    </a>
  )
}

export default function Hero() {
  return (
    <section
      className="relative min-h-screen flex items-center overflow-hidden pt-16"
      style={{
        background:
          'radial-gradient(ellipse 60% 50% at 75% 40%, rgba(21,57,24,0.06) 0%, transparent 60%), radial-gradient(ellipse 50% 40% at 25% 80%, rgba(184,125,40,0.04) 0%, transparent 50%), #E8E3D6',
      }}
    >
      <div className="max-w-6xl mx-auto px-6 py-24 w-full">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left — text */}
          <div>
            {/* Tag */}
            <div className="inline-flex items-center gap-2 bg-primary/8 text-primary px-4 py-2 rounded-full text-xs font-mono font-medium mb-8 border border-primary/10">
              <span className="w-1.5 h-1.5 rounded-full bg-score-excellent animate-pulse" />
              Бесплатно · iOS и Android
            </div>

            {/* Headline */}
            <h1 className="font-display font-black text-fg mb-6 leading-[0.9]" style={{ fontSize: 'clamp(3rem, 7vw, 5rem)' }}>
              Знай,<br />
              что ты<br />
              <em className="not-italic text-primary">ешь.</em>
            </h1>

            {/* Description */}
            <p className="text-lg text-muted-fg leading-relaxed mb-10 max-w-md">
              Маяк расшифровывает этикетки продуктов — сканируй штрихкод
              и сразу видишь оценку, скрытые риски и более здоровые альтернативы.
              Без рекламы. Только факты.
            </p>

            {/* Store buttons */}
            <div className="flex flex-wrap gap-3">
              <StoreButton store="apple" />
              <StoreButton store="google" />
            </div>

            {/* Social proof */}
            <p className="mt-8 text-xs text-muted-fg font-mono">
              Оценки строятся на данных <span className="text-fg font-medium">ВОЗ</span> · <span className="text-fg font-medium">EFSA</span> · <span className="text-fg font-medium">Open Food Facts</span>
            </p>
          </div>

          {/* Right — phone mockup */}
          <div className="flex justify-center lg:justify-end">
            <PhoneMockup />
          </div>
        </div>
      </div>

      {/* Bottom wave separator */}
      <div className="absolute bottom-0 left-0 right-0 h-16 pointer-events-none"
        style={{ background: 'linear-gradient(to bottom, transparent, rgba(232,227,214,0.6))' }}
      />
    </section>
  )
}
