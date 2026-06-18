const YEAR = new Date().getFullYear()

const nav = [
  {
    title: 'Приложение',
    links: [
      { label: 'О Маяке', href: '#trust' },
      { label: 'Как работает оценка', href: '#how' },
      { label: 'Независимость', href: '#trust' },
      { label: 'Маяк Премиум', href: '#pricing' },
    ],
  },
  {
    title: 'Поддержка',
    links: [
      { label: 'База знаний', href: '#' },
      { label: 'Сообщить об ошибке', href: 'mailto:admin@foodmayak.ru' },
      { label: 'Добавить продукт', href: 'mailto:admin@foodmayak.ru' },
      { label: 'Контакты', href: 'mailto:admin@foodmayak.ru' },
    ],
  },
  {
    title: 'Правовая информация',
    links: [
      { label: 'Публичная оферта', href: '?page=offer' },
      { label: 'Пользовательское соглашение', href: '?page=terms' },
      { label: 'Политика конфиденциальности', href: '?page=privacy' },
      { label: 'Обработка персональных данных', href: '?page=personal-data' },
      { label: 'Согласие на обработку ПДн', href: '?page=consent' },
      { label: 'Политика cookies', href: '?page=cookies' },
      { label: 'Лицензии на данные', href: '?page=licenses' },
    ],
  },
]

export default function Footer() {
  return (
    <footer className="bg-card border-t border-fg/6">
      {/* Main footer */}
      <div className="max-w-6xl mx-auto px-6 py-16">
        <div className="grid md:grid-cols-4 gap-12">
          {/* Brand */}
          <div>
            <a href="/" className="font-display text-2xl font-black text-primary block mb-4">
              МАЯК
            </a>
            <p className="text-sm text-muted-fg leading-relaxed mb-6">
              Помогаем делать осознанный выбор продуктов питания на основе научных данных.
            </p>
            {/* Socials */}
            <div className="flex gap-3">
              <a
                href="#"
                className="w-9 h-9 rounded-xl bg-fg/5 hover:bg-fg/10 transition-colors flex items-center justify-center text-sm"
                aria-label="Telegram"
              >
                ✈️
              </a>
              <a
                href="#"
                className="w-9 h-9 rounded-xl bg-fg/5 hover:bg-fg/10 transition-colors flex items-center justify-center text-sm"
                aria-label="Instagram"
              >
                📸
              </a>
            </div>
          </div>

          {/* Nav columns */}
          {nav.map(col => (
            <div key={col.title}>
              <h4 className="text-xs font-mono text-muted-fg tracking-widest uppercase mb-4">{col.title}</h4>
              <ul className="space-y-3">
                {col.links.map(l => (
                  <li key={l.label}>
                    <a
                      href={l.href}
                      className="text-sm text-muted-fg hover:text-fg transition-colors duration-200"
                    >
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      {/* Legal bottom bar */}
      <div className="border-t border-fg/6">
        <div className="max-w-6xl mx-auto px-6 py-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <p className="text-xs text-muted-fg">
            © {YEAR} МАЯК. Заботимся о здоровье.
          </p>
          <div className="text-[11px] text-muted-fg leading-relaxed md:text-right space-y-0.5">
            <p>
              ИП Головлев Иван Александрович · ИНН&nbsp;770201291441 · ОГРНИП&nbsp;325774600759217
            </p>
            <p>
              <a href="tel:+79854345627" className="hover:text-fg transition-colors">+7&nbsp;985&nbsp;434-56-27</a>
              {' · '}
              <a href="mailto:admin@foodmayak.ru" className="hover:text-fg transition-colors">admin@foodmayak.ru</a>
            </p>
            <p>
              ООО «Банк Точка» · р/с&nbsp;40802810220000808347 · БИК&nbsp;044525104
            </p>
          </div>
        </div>
      </div>

      {/* Disclaimer */}
      <div className="bg-fg/3 border-t border-fg/5">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <p className="text-[10px] text-muted-fg leading-relaxed text-center max-w-4xl mx-auto">
            Информация в приложении Маяк носит исключительно информационный характер и не является медицинской рекомендацией.
            Оценки продуктов основаны на общедоступных научных данных и не заменяют консультацию с врачом или диетологом.
            Приложение не предназначено для диагностики, лечения или профилактики заболеваний.
            Данные о продуктах предоставлены из открытых источников и могут не отражать актуальный состав на момент покупки.
            Производители вправе изменять рецептуру без предварительного уведомления.
          </p>
        </div>
      </div>
    </footer>
  )
}
