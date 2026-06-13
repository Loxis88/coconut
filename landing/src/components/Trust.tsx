import { useInView } from '../hooks/useInView'

const pillars = [
  {
    icon: '🔬',
    title: 'Научная база',
    body: 'Оценки строятся на данных ВОЗ, EFSA, USDA и открытых продуктовых базах. Алгоритм учитывает состав, степень промышленной обработки по NOVA и пищевую ценность.',
    tag: 'Без рекламных соглашений',
  },
  {
    icon: '🚫',
    title: 'Ноль влияния брендов',
    body: 'Ни один производитель не может купить место в выдаче, улучшить оценку или скрыть риски. Рейтинг продукта определяет только его состав — не маркетинговый бюджет.',
    tag: 'Независимая редакция',
  },
  {
    icon: '⚡',
    title: 'Мгновенный результат',
    body: 'Оценка 0–100 появляется за секунду после сканирования. Приложение работает офлайн — данные по популярным продуктам хранятся прямо в телефоне.',
    tag: 'Работает без интернета',
  },
]

export default function Trust() {
  const { ref, inView } = useInView()

  return (
    <section
      id="trust"
      ref={ref as React.RefObject<HTMLElement>}
      className="py-24 border-t border-fg/6"
    >
      <div className="max-w-6xl mx-auto px-6">
        {/* Section label */}
        <p className={`font-mono text-xs text-muted-fg tracking-widest uppercase mb-12 text-center fade-up ${inView ? 'visible' : ''}`}>
          Почему маяк
        </p>

        <div className="grid md:grid-cols-3 gap-6">
          {pillars.map((p, i) => (
            <div
              key={p.title}
              className={`bg-card rounded-3xl p-8 border border-fg/5 hover:border-fg/10 transition-all duration-300 hover:-translate-y-1 fade-up delay-${i + 1} ${inView ? 'visible' : ''}`}
            >
              <div className="text-4xl mb-5">{p.icon}</div>
              <h3 className="font-display font-black text-xl text-fg mb-3">{p.title}</h3>
              <p className="text-sm text-muted-fg leading-relaxed mb-5">{p.body}</p>
              <span className="inline-block bg-primary/8 text-primary text-[10px] font-mono px-3 py-1 rounded-full border border-primary/10">
                {p.tag}
              </span>
            </div>
          ))}
        </div>

        {/* Independence statement */}
        <div className={`mt-12 bg-card rounded-3xl p-8 border border-fg/5 flex flex-col md:flex-row items-start md:items-center gap-6 fade-up delay-4 ${inView ? 'visible' : ''}`}>
          <div className="text-3xl flex-shrink-0">🛡️</div>
          <div>
            <h4 className="font-bold text-fg mb-1">Декларация независимости</h4>
            <p className="text-sm text-muted-fg leading-relaxed max-w-2xl">
              Маяк финансируется исключительно за счёт премиум-подписок пользователей.
              Мы не принимаем рекламу, не заключаем спонсорских соглашений с производителями продуктов питания
              и не продаём данные третьим лицам. Конфликт интересов исключён структурно.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
