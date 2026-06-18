import LegalLayout from './LegalLayout'

const sources = [
  {
    name: 'Open Food Facts',
    url: 'https://world.openfoodfacts.org',
    license: 'Open Database License (ODbL) v1.0',
    licenseUrl: 'https://opendatacommons.org/licenses/odbl/1-0/',
    desc: 'Коллаборативная база данных продуктов питания с составом, пищевой ценностью и штрихкодами. Основной источник информации о продуктах в Маяке.',
    attribution: 'Данные предоставлены Open Food Facts (openfoodfacts.org), доступны по лицензии ODbL.',
  },
  {
    name: 'USDA FoodData Central',
    url: 'https://fdc.nal.usda.gov',
    license: 'Public Domain (CC0)',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    desc: 'База данных Министерства сельского хозяйства США с детальными нутриентными профилями продуктов питания.',
    attribution: 'U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.',
  },
  {
    name: 'EFSA (European Food Safety Authority)',
    url: 'https://www.efsa.europa.eu',
    license: 'Creative Commons Attribution 4.0 (CC BY 4.0)',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
    desc: 'Научные заключения Европейского агентства по безопасности продуктов питания об оценке риска пищевых добавок, ингредиентов и загрязнителей.',
    attribution: '© European Food Safety Authority, efsa.europa.eu.',
  },
  {
    name: 'WHO / ВОЗ — Нормы питательных веществ',
    url: 'https://www.who.int/nutrition',
    license: 'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 IGO',
    licenseUrl: 'https://creativecommons.org/licenses/by-nc-sa/3.0/igo/',
    desc: 'Рекомендации Всемирной организации здравоохранения по допустимому суточному потреблению соли, сахара, насыщенных жиров и других нутриентов.',
    attribution: '© World Health Organization, who.int. Использование в некоммерческих и образовательных целях.',
  },
  {
    name: 'NOVA Food Classification',
    url: 'https://www.fao.org/nutrition/education/food-dietary-guidelines/background/nova-food-classification',
    license: 'Académica / цитируется',
    licenseUrl: '#',
    desc: 'Система классификации степени промышленной обработки продуктов (1–4), разработанная исследовательской группой NUPENS / Университет Сан-Паулу.',
    attribution: 'Monteiro CA et al. (2019). Ultra-processed foods: what they are and how to identify them. Public Health Nutrition.',
  },
  {
    name: 'JECFA (Joint FAO/WHO Expert Committee on Food Additives)',
    url: 'https://www.fao.org/food/food-safety-quality/scientific-advice/jecfa',
    license: 'Public Domain',
    licenseUrl: '#',
    desc: 'Международная экспертная база данных по безопасности пищевых добавок: ADI (допустимое суточное потребление) и классификации рисков.',
    attribution: 'FAO/WHO Joint Expert Committee on Food Additives.',
  },
]

export default function Licenses() {
  return (
    <LegalLayout title="Лицензии на данные" updated="14 июня 2026 г.">
      <div className="prose-legal">
        <div className="notice">
          Приложение «Маяк» использует данные из открытых международных источников.
          Ниже перечислены все источники, их лицензии и требования по атрибуции.
          Маяк соблюдает условия всех указанных лицензий.
        </div>

        {sources.map((s) => (
          <div
            key={s.name}
            style={{
              border: '1px solid rgba(12,26,9,0.08)',
              borderRadius: 16,
              padding: '1.25rem 1.5rem',
              marginBottom: '1rem',
              background: 'var(--color-card)',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
              <div>
                <strong style={{ fontSize: '0.95rem', color: 'var(--color-fg)' }}>{s.name}</strong>
                &nbsp;
                <a href={s.url} target="_blank" rel="noreferrer"
                  style={{ fontSize: '0.75rem', color: 'var(--color-primary)' }}>
                  {s.url.replace('https://', '')}
                </a>
              </div>
              <a
                href={s.licenseUrl}
                target="_blank"
                rel="noreferrer"
                style={{
                  fontSize: '0.7rem',
                  fontFamily: 'var(--font-mono)',
                  background: 'rgba(21,57,24,0.08)',
                  color: 'var(--color-primary)',
                  border: '1px solid rgba(21,57,24,0.12)',
                  padding: '2px 10px',
                  borderRadius: 99,
                  whiteSpace: 'nowrap',
                }}
              >
                {s.license}
              </a>
            </div>
            <p style={{ marginTop: '0.5rem', marginBottom: '0.5rem' }}>{s.desc}</p>
            <p style={{
              fontSize: '0.78rem',
              fontFamily: 'var(--font-mono)',
              color: 'var(--color-muted-fg)',
              background: 'rgba(12,26,9,0.04)',
              padding: '0.5rem 0.75rem',
              borderRadius: 8,
              marginBottom: 0,
            }}>
              {s.attribution}
            </p>
          </div>
        ))}

        <h2>Лицензия Маяка на собственный контент</h2>
        <p>
          Алгоритм оценки продуктов, дизайн, тексты и код приложения «Маяк» являются
          собственностью ИП Головлева Ивана Александровича и защищены законодательством
          об интеллектуальной собственности. Все права защищены.
        </p>
        <p>
          Данные из открытых источников, полученные на условиях лицензий, разрешающих
          производные работы (ODbL, CC BY, CC0), используются в соответствии
          с требованиями этих лицензий, включая обязательную атрибуцию.
        </p>

        <h2>Сообщить об ошибке в данных</h2>
        <p>
          Если вы обнаружили неверный состав, некорректную оценку или устаревшую информацию
          о продукте — сообщите нам: <a href="mailto:admin@foodmayak.ru">admin@foodmayak.ru</a>.
          Мы проверим и исправим данные в течение 7 рабочих дней.
        </p>
      </div>
    </LegalLayout>
  )
}
