import { useInView } from '../hooks/useInView'

/* ── Shared score ring ── */
function ScoreRing({ score, size = 80, stroke = 6 }: { score: number; size?: number; stroke?: number }) {
  const color =
    score >= 80 ? '#1E6B28' : score >= 60 ? '#4A9152' : score >= 40 ? '#B87D28' : '#C03B32'
  const label =
    score >= 80 ? 'Отлично' : score >= 60 ? 'Хорошо' : score >= 40 ? 'Спорно' : 'Плохо'
  const r = (size - stroke) / 2
  const circ = 2 * Math.PI * r
  const offset = circ - (score / 100) * circ
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#DDD8CB" strokeWidth={stroke} />
        <circle
          cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke}
          strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="font-black leading-none" style={{ fontSize: size * 0.26, color }}>{score}</span>
        <span className="font-mono leading-none mt-0.5" style={{ fontSize: size * 0.1, color }}>{label}</span>
      </div>
    </div>
  )
}

/* ── Phone shell ── */
function PhoneShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative w-56 h-[460px] bg-bg rounded-[36px] border-2 border-fg/10 shadow-2xl overflow-hidden flex-shrink-0">
      {/* Status bar */}
      <div className="h-7 flex items-center justify-between px-5 pt-1.5">
        <span className="text-[9px] text-fg/30 font-mono">9:41</span>
        <div className="w-14 h-3.5 bg-fg/8 rounded-b-xl" />
        <div className="w-4 h-2 rounded-sm bg-fg/20" />
      </div>
      {children}
    </div>
  )
}

/* ── Feature 1: Score screen ── */
function ScoreScreen() {
  return (
    <PhoneShell>
      <div className="px-4 py-2">
        <p className="text-[10px] text-primary font-medium">← Сканер</p>
      </div>
      <div className="px-4 pb-2">
        <p className="text-[10px] text-muted-fg font-mono">Нутелла · Сладости</p>
        <p className="text-[14px] font-bold text-fg leading-tight">Шоколадная паста</p>
      </div>
      <div className="flex justify-center py-3">
        <ScoreRing score={28} size={88} />
      </div>
      {/* Risk items */}
      <div className="px-4 space-y-2">
        {[
          { text: '56% сахара — в 2.5× выше нормы ВОЗ', color: '#C03B32' },
          { text: 'Пальмовое масло — насыщенные жиры', color: '#C03B32' },
          { text: 'NOVA 4 — ультра-переработанный', color: '#B87D28' },
          { text: 'Калорийность 539 ккал / 100 г', color: '#B87D28' },
        ].map(({ text, color }) => (
          <div key={text} className="flex items-start gap-2">
            <div className="w-1.5 h-1.5 rounded-full flex-shrink-0 mt-1.5" style={{ background: color }} />
            <span className="text-[10px] text-fg leading-snug">{text}</span>
          </div>
        ))}
      </div>
      {/* Find alt button */}
      <div className="absolute bottom-10 left-4 right-4">
        <div className="bg-primary rounded-xl py-2.5 text-center">
          <span className="text-[11px] font-semibold text-white">Найти альтернативу →</span>
        </div>
      </div>
    </PhoneShell>
  )
}

/* ── Feature 2: Ingredients screen ── */
function IngredientsScreen() {
  const ingredients = [
    { name: 'Сахар', pct: '56%', status: 'bad', desc: 'Первый ингредиент' },
    { name: 'Пальмовое масло', pct: '20%', status: 'bad', desc: 'Насыщенные жиры' },
    { name: 'Лецитин Е322', pct: null, status: 'ok', desc: 'Эмульгатор' },
    { name: 'Лесные орехи', pct: '13%', status: 'good', desc: 'Мононенасыщенные жиры' },
    { name: 'Обезжиренное какао', pct: '7.4%', status: 'good', desc: 'Антиоксиданты' },
  ]
  const colors: Record<string, string> = { bad: '#C03B32', ok: '#B87D28', good: '#1E6B28' }
  const bg: Record<string, string> = { bad: '#ffd9df', ok: '#ffe2cc', good: '#d7f5e6' }

  return (
    <PhoneShell>
      <div className="px-4 py-2 flex items-center justify-between">
        <p className="text-[10px] text-primary font-medium">← Состав</p>
        <span className="text-[10px] font-mono text-muted-fg">5 ингредиентов</span>
      </div>
      <div className="px-4 space-y-2 pt-1">
        {ingredients.map(({ name, pct, status, desc }) => (
          <div key={name} className="flex items-center gap-2 bg-card rounded-xl p-2.5">
            <div
              className="w-2 h-2 rounded-full flex-shrink-0"
              style={{ background: colors[status] }}
            />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-[11px] font-semibold text-fg truncate">{name}</span>
                {pct && (
                  <span
                    className="text-[9px] font-mono px-1.5 py-0.5 rounded-md flex-shrink-0"
                    style={{ background: bg[status], color: colors[status] }}
                  >
                    {pct}
                  </span>
                )}
              </div>
              <p className="text-[9px] text-muted-fg">{desc}</p>
            </div>
          </div>
        ))}
      </div>
    </PhoneShell>
  )
}

/* ── Feature 3: Alternatives screen ── */
function AlternativesScreen() {
  return (
    <PhoneShell>
      <div className="px-4 py-2">
        <p className="text-[10px] text-primary font-medium">← Альтернативы</p>
      </div>
      <div className="px-4 pt-1 space-y-3">
        {/* Bad product */}
        <div>
          <p className="text-[9px] font-mono text-muted-fg uppercase tracking-wide mb-1.5">Сейчас</p>
          <div className="bg-score-poor/8 border border-score-poor/20 rounded-2xl p-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-score-poor/15 flex items-center justify-center text-lg flex-shrink-0">🍫</div>
            <div className="flex-1 min-w-0">
              <p className="text-[11px] font-bold text-fg truncate">Нутелла</p>
              <p className="text-[9px] text-muted-fg">Шоколадная паста</p>
            </div>
            <ScoreRing score={28} size={44} stroke={4} />
          </div>
        </div>

        {/* Arrow */}
        <div className="flex justify-center text-muted-fg text-lg">↓</div>

        {/* Better products */}
        <div>
          <p className="text-[9px] font-mono text-muted-fg uppercase tracking-wide mb-1.5">Лучше выбрать</p>
          <div className="space-y-2">
            {[
              { icon: '🥜', brand: 'Семь орехов', name: 'Паста из фундука', score: 62 },
              { icon: '🍫', brand: 'Lindt', name: 'Тёмный шоколад 85%', score: 73 },
            ].map(({ icon, brand, name, score }) => (
              <div key={name} className="bg-score-excellent/8 border border-score-excellent/20 rounded-2xl p-3 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-score-excellent/15 flex items-center justify-center text-lg flex-shrink-0">{icon}</div>
                <div className="flex-1 min-w-0">
                  <p className="text-[11px] font-bold text-fg truncate">{name}</p>
                  <p className="text-[9px] text-muted-fg">{brand}</p>
                </div>
                <ScoreRing score={score} size={44} stroke={4} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </PhoneShell>
  )
}

/* ── Feature section layout ── */
interface FeatureProps {
  tag: string
  headline: string
  body: string
  claims: string[]
  screen: React.ReactNode
  flip?: boolean
  inView: boolean
  index: number
}

function Feature({ tag, headline, body, claims, screen, flip, inView, index }: FeatureProps) {
  const textSide = (
    <div className={`fade-up delay-${index + 1} ${inView ? 'visible' : ''}`}>
      <span className="inline-block font-mono text-xs text-primary bg-primary/8 px-3 py-1.5 rounded-full border border-primary/10 mb-5">
        {tag}
      </span>
      <h2 className="font-display font-black text-fg leading-tight mb-4" style={{ fontSize: 'clamp(1.75rem, 3.5vw, 2.5rem)' }}>
        {headline}
      </h2>
      <p className="text-muted-fg leading-relaxed mb-6 max-w-md">{body}</p>
      <ul className="space-y-3">
        {claims.map(c => (
          <li key={c} className="flex items-start gap-3">
            <div className="w-5 h-5 rounded-full bg-score-excellent/15 flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-[9px] text-score-excellent font-bold">✓</span>
            </div>
            <span className="text-sm text-fg leading-snug">{c}</span>
          </li>
        ))}
      </ul>
    </div>
  )

  const visual = (
    <div className={`flex justify-center fade-up delay-2 ${inView ? 'visible' : ''}`}>
      {screen}
    </div>
  )

  return (
    <div className={`grid lg:grid-cols-2 gap-16 items-center ${flip ? 'lg:[&>:first-child]:order-2' : ''}`}>
      {flip ? visual : textSide}
      {flip ? textSide : visual}
    </div>
  )
}

/* ── Main export ── */
export default function Features() {
  const { ref: ref1, inView: inView1 } = useInView()
  const { ref: ref2, inView: inView2 } = useInView()
  const { ref: ref3, inView: inView3 } = useInView()

  return (
    <section id="features" className="py-24">
      <div className="max-w-6xl mx-auto px-6 space-y-32">
        {/* Feature 1 — Score */}
        <div ref={ref1 as React.RefObject<HTMLDivElement>}>
          <Feature
            tag="01 — Оценка"
            headline={`Один балл.\nВсё ясно.`}
            body="Маяк анализирует состав, степень промышленной обработки по классификации NOVA и пищевую ценность — и выдаёт единую оценку от 0 до 100. Никакого жаргона, никакой путаницы."
            claims={[
              'Оценка строится по 12 независимым критериям',
              'Учитывается степень обработки (NOVA 1–4)',
              'Сравнение с нормами ВОЗ по соли, сахару и жирам',
              'Понятный результат без медицинского образования',
            ]}
            screen={<ScoreScreen />}
            inView={inView1}
            index={1}
          />
        </div>

        {/* Feature 2 — Ingredients */}
        <div ref={ref2 as React.RefObject<HTMLDivElement>}>
          <Feature
            tag="02 — Состав"
            headline="Состав без тайн."
            body="Каждый ингредиент проверяется по международным базам EFSA и JECFA. Консерванты, усилители вкуса, аллергены и красители — выделены сразу, с пояснением что это и зачем производитель это добавил."
            claims={[
              'Более 10 000 ингредиентов в базе с пояснениями',
              'Аллергены выделяются отдельно и с предупреждением',
              'E-номера расшифрованы: риск от низкого до высокого',
              'Показывает реальный процент каждого ингредиента',
            ]}
            screen={<IngredientsScreen />}
            flip
            inView={inView2}
            index={1}
          />
        </div>

        {/* Feature 3 — Alternatives */}
        <div ref={ref3 as React.RefObject<HTMLDivElement>}>
          <Feature
            tag="03 — Альтернативы"
            headline="Найди лучше."
            body="Нашли вредный продукт? Маяк подберёт более здоровую альтернативу из той же категории с детальным сравнением. Один свайп — и вы уже знаете, что купить вместо."
            claims={[
              'Альтернативы из той же категории и ценового сегмента',
              'Сравнение по всем 12 критериям рядом',
              'Список растёт: уже более 50 000 продуктов в базе',
              'Работает офлайн — не нужен интернет в магазине',
            ]}
            screen={<AlternativesScreen />}
            inView={inView3}
            index={1}
          />
        </div>
      </div>
    </section>
  )
}
