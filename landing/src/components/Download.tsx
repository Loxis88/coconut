import { Apple, Play } from 'lucide-react'
import { useInView } from '../hooks/useInView'

const claims = [
  { v: '50 000+', l: 'продуктов в базе' },
  { v: '10 000+', l: 'ингредиентов расшифровано' },
  { v: '12', l: 'критериев оценки' },
  { v: '0 ₽', l: 'базовый доступ' },
]

export default function Download() {
  const { ref, inView } = useInView()

  return (
    <section
      id="download"
      ref={ref as React.RefObject<HTMLElement>}
      className="py-24 relative overflow-hidden"
      style={{ background: '#0D1F0F' }}
    >
      {/* Background texture */}
      <div
        className="absolute inset-0 pointer-events-none opacity-30"
        style={{
          background:
            'radial-gradient(ellipse 60% 70% at 80% 50%, rgba(21,57,24,0.6) 0%, transparent 60%), radial-gradient(ellipse 50% 50% at 20% 60%, rgba(184,125,40,0.15) 0%, transparent 60%)',
        }}
      />

      <div className="max-w-6xl mx-auto px-6 relative">
        {/* Stats row */}
        <div className={`grid grid-cols-2 md:grid-cols-4 gap-6 mb-20 fade-up ${inView ? 'visible' : ''}`}>
          {claims.map(({ v, l }) => (
            <div key={l} className="text-center">
              <div className="font-display font-black text-white leading-none mb-1" style={{ fontSize: 'clamp(1.8rem, 4vw, 2.8rem)' }}>
                {v}
              </div>
              <div className="text-xs text-white/40 font-mono">{l}</div>
            </div>
          ))}
        </div>

        {/* CTA block */}
        <div className={`text-center fade-up delay-1 ${inView ? 'visible' : ''}`}>
          <p className="font-mono text-xs text-white/40 tracking-widest uppercase mb-4">Начни прямо сейчас</p>
          <h2
            className="font-display font-black text-white leading-tight mb-6"
            style={{ fontSize: 'clamp(2.5rem, 6vw, 4.5rem)' }}
          >
            Начни есть<br />
            <em className="not-italic" style={{ color: '#4A9152' }}>осознанно.</em>
          </h2>
          <p className="text-white/50 text-lg mb-10 max-w-lg mx-auto">
            Бесплатно. Без обязательной регистрации. Работает офлайн.
          </p>

          {/* Store buttons */}
          <div className="flex flex-wrap justify-center gap-4 mb-12">
            <a
              href="#"
              className="inline-flex items-center gap-3 bg-white text-fg px-6 py-4 rounded-2xl hover:bg-white/90 transition-all duration-200 hover:-translate-y-0.5 hover:shadow-xl"
            >
              <Apple size={24} className="flex-shrink-0" />
              <div className="text-left">
                <div className="text-[10px] opacity-50 leading-none mb-0.5">Скачать в</div>
                <div className="text-sm font-bold leading-none">App Store</div>
              </div>
            </a>
            <a
              href="#"
              className="inline-flex items-center gap-3 bg-white text-fg px-6 py-4 rounded-2xl hover:bg-white/90 transition-all duration-200 hover:-translate-y-0.5 hover:shadow-xl"
            >
              <Play size={22} className="flex-shrink-0 fill-fg" />
              <div className="text-left">
                <div className="text-[10px] opacity-50 leading-none mb-0.5">Доступно в</div>
                <div className="text-sm font-bold leading-none">Google Play</div>
              </div>
            </a>
          </div>

          {/* Premium note */}
          <div className="inline-flex flex-col sm:flex-row items-center gap-2 bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-sm">
            <span className="text-white/60">Базовый доступ — бесплатно навсегда.</span>
            <span className="text-white/60">
              Расширенная аналитика — <strong className="text-white">Маяк Премиум.</strong>
            </span>
          </div>
        </div>
      </div>
    </section>
  )
}
