import { Check } from 'lucide-react'
import { useInView } from '../hooks/useInView'

/* Платёжная ссылка ЮKassa — заменить на реальную ссылку/виджет оплаты */
const PAY_URL = '#'

/* Способы оплаты, подключённые в ЮKassa */
const payMethods = ['СБП', 'Карты РФ · МИР', 'Т‑Банк']

const features = [
  'Расширенная аналитика рациона',
  'История сканирований без ограничений',
  'Синхронизация между устройствами',
  'Детальная расшифровка состава',
  'Персональные рекомендации',
  'Поддержка развития проекта',
]

const plans = [
  {
    id: 'monthly',
    name: 'Помесячно',
    price: '299',
    period: '₽ / месяц',
    note: 'Оплата каждый месяц, отмена в любой момент',
    highlight: false,
    badge: null as string | null,
  },
  {
    id: 'yearly',
    name: 'На год',
    price: '1 990',
    period: '₽ / год',
    note: 'Это ~166 ₽ в месяц — выгоднее на 45%',
    highlight: true,
    badge: 'Выгодно',
  },
]

export default function Pricing() {
  const { ref, inView } = useInView()

  return (
    <section
      id="pricing"
      ref={ref as React.RefObject<HTMLElement>}
      className="py-24 bg-bg"
    >
      <div className="max-w-5xl mx-auto px-6">
        {/* Header */}
        <div className={`text-center mb-14 fade-up ${inView ? 'visible' : ''}`}>
          <p className="font-mono text-xs text-muted-fg tracking-widest uppercase mb-4">Маяк Премиум</p>
          <h2
            className="font-display font-black text-fg leading-tight mb-4"
            style={{ fontSize: 'clamp(2rem, 5vw, 3.2rem)' }}
          >
            Больше пользы<br />
            <em className="not-italic text-primary">за честную цену.</em>
          </h2>
          <p className="text-muted-fg text-lg max-w-lg mx-auto">
            Базовый доступ остаётся бесплатным навсегда. Премиум открывает расширенную
            аналитику и помогает развивать проект.
          </p>
        </div>

        {/* Plans */}
        <div className={`grid md:grid-cols-2 gap-6 max-w-3xl mx-auto fade-up delay-1 ${inView ? 'visible' : ''}`}>
          {plans.map(plan => (
            <div
              key={plan.id}
              className={`relative rounded-3xl p-8 flex flex-col border transition-all duration-200 ${
                plan.highlight
                  ? 'bg-primary text-white border-primary shadow-xl md:-translate-y-2'
                  : 'bg-card text-fg border-fg/8'
              }`}
            >
              {plan.badge && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-accent text-white text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wide">
                  {plan.badge}
                </span>
              )}

              <h3 className={`font-display font-black text-xl mb-2 ${plan.highlight ? 'text-white' : 'text-fg'}`}>
                {plan.name}
              </h3>

              <div className="flex items-baseline gap-1.5 mb-1">
                <span className="font-display font-black leading-none" style={{ fontSize: 'clamp(2.2rem, 5vw, 3rem)' }}>
                  {plan.price}
                </span>
                <span className={`text-sm ${plan.highlight ? 'text-white/60' : 'text-muted-fg'}`}>{plan.period}</span>
              </div>
              <p className={`text-sm mb-7 ${plan.highlight ? 'text-white/60' : 'text-muted-fg'}`}>{plan.note}</p>

              <ul className="space-y-3 mb-8 flex-1">
                {features.map(f => (
                  <li key={f} className="flex items-start gap-2.5 text-sm">
                    <Check
                      size={18}
                      className={`flex-shrink-0 mt-0.5 ${plan.highlight ? 'text-white' : 'text-primary'}`}
                    />
                    <span className={plan.highlight ? 'text-white/85' : 'text-fg/80'}>{f}</span>
                  </li>
                ))}
              </ul>

              <a
                href={PAY_URL}
                className={`block text-center font-semibold px-6 py-4 rounded-2xl transition-all duration-200 hover:-translate-y-0.5 ${
                  plan.highlight
                    ? 'bg-white text-primary hover:bg-white/90 hover:shadow-xl'
                    : 'bg-primary text-white hover:bg-primary/90 hover:shadow-lg'
                }`}
              >
                Оплатить
              </a>
            </div>
          ))}
        </div>

        {/* Payment methods */}
        <div className={`mt-12 fade-up delay-2 ${inView ? 'visible' : ''}`}>
          <p className="text-center font-mono text-xs text-muted-fg tracking-widest uppercase mb-4">
            Способы оплаты
          </p>
          <div className="flex flex-wrap justify-center gap-3 mb-2">
            {payMethods.map(m => (
              <span
                key={m}
                className="inline-flex items-center bg-card border border-fg/10 rounded-xl px-4 py-2.5 text-sm font-semibold text-fg"
              >
                {m}
              </span>
            ))}
          </div>
          <p className="text-center text-xs text-muted-fg">
            Платежи обрабатывает <strong className="text-fg">ЮKassa</strong> по стандарту
            безопасности PCI DSS. Данные карты мы не получаем и не храним.
          </p>
        </div>

        {/* Recurrent + legal */}
        <div className="mt-8 max-w-xl mx-auto text-center space-y-3">
          <p className="text-xs text-muted-fg">
            Подписка продлевается автоматически: по окончании периода списывается стоимость
            следующего (299 ₽ в месяц или 1 990 ₽ в год). Отменить автопродление можно в любой
            момент в настройках аккаунта или письмом на{' '}
            <a href="mailto:admin@foodmayak.ru" className="text-primary underline">admin@foodmayak.ru</a>.
          </p>
          <p className="text-xs text-muted-fg">
            Нажимая «Оплатить», вы принимаете условия{' '}
            <a href="?page=offer" className="text-primary underline">Публичной оферты</a> и даёте{' '}
            <a href="?page=consent" className="text-primary underline">согласие на обработку персональных данных</a>{' '}
            согласно{' '}
            <a href="?page=privacy" className="text-primary underline">Политике конфиденциальности</a>.
          </p>
        </div>
      </div>
    </section>
  )
}
