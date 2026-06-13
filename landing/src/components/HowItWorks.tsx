import { useInView } from '../hooks/useInView'

const steps = [
  {
    n: '01',
    icon: '📷',
    title: 'Наведи камеру',
    body: 'Отсканируй штрихкод любого продукта в магазине, дома или в кафе — одним нажатием без лишних шагов.',
  },
  {
    n: '02',
    icon: '⚡',
    title: 'Получи оценку',
    body: 'За секунду видишь итоговый балл 0–100, разбор состава, пищевую ценность и предупреждения о рисках.',
  },
  {
    n: '03',
    icon: '🛒',
    title: 'Выбирай осознанно',
    body: 'Оставь продукт на полке или найди в один тап более здоровую альтернативу в той же ценовой категории.',
  },
]

export default function HowItWorks() {
  const { ref, inView } = useInView()

  return (
    <section
      id="how"
      ref={ref as React.RefObject<HTMLElement>}
      className="py-24 bg-card border-y border-fg/5"
    >
      <div className="max-w-6xl mx-auto px-6">
        <div className={`text-center mb-16 fade-up ${inView ? 'visible' : ''}`}>
          <p className="font-mono text-xs text-muted-fg tracking-widest uppercase mb-4">Как работает</p>
          <h2 className="font-display font-black text-fg leading-tight" style={{ fontSize: 'clamp(2rem, 4vw, 3rem)' }}>
            Три шага к осознанному выбору
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-8 relative">
          {/* Connector line (desktop) */}
          <div className="hidden md:block absolute top-12 left-1/3 right-1/3 h-px bg-fg/10" />

          {steps.map((step, i) => (
            <div key={step.n} className={`relative fade-up delay-${i + 1} ${inView ? 'visible' : ''}`}>
              {/* Number */}
              <div className="w-10 h-10 rounded-full bg-fg text-bg flex items-center justify-center text-xs font-mono font-bold mb-5 relative z-10">
                {step.n}
              </div>

              <div className="text-4xl mb-4">{step.icon}</div>
              <h3 className="font-display font-black text-xl text-fg mb-3">{step.title}</h3>
              <p className="text-sm text-muted-fg leading-relaxed">{step.body}</p>
            </div>
          ))}
        </div>

        {/* Bottom claim */}
        <div className={`mt-16 text-center fade-up delay-4 ${inView ? 'visible' : ''}`}>
          <p className="text-muted-fg text-sm">
            В среднем пользователи Маяка тратят{' '}
            <strong className="text-fg">менее 8 секунд</strong> на проверку одного продукта.
          </p>
        </div>
      </div>
    </section>
  )
}
