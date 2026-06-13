import { useState, useEffect } from 'react'
import { Menu, X } from 'lucide-react'

export default function Navbar() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 20)
    window.addEventListener('scroll', fn)
    return () => window.removeEventListener('scroll', fn)
  }, [])

  const links = [
    { href: '#features', label: 'Возможности' },
    { href: '#how', label: 'Как работает' },
    { href: '#trust', label: 'Независимость' },
  ]

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? 'bg-bg/95 backdrop-blur-md shadow-sm' : 'bg-transparent'
      }`}
    >
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <a href="/" className="font-display text-2xl font-black text-primary tracking-tight select-none">
          МАЯК
        </a>

        {/* Desktop links */}
        <div className="hidden md:flex items-center gap-8">
          {links.map(l => (
            <a
              key={l.href}
              href={l.href}
              className="text-sm text-muted-fg hover:text-fg transition-colors duration-200"
            >
              {l.label}
            </a>
          ))}
        </div>

        {/* CTA + mobile toggle */}
        <div className="flex items-center gap-3">
          <a
            href="#download"
            className="hidden md:inline-flex items-center bg-primary text-white text-sm font-semibold px-5 py-2.5 rounded-xl hover:bg-primary/90 transition-all duration-200 hover:-translate-y-px"
          >
            Скачать бесплатно
          </a>
          <button
            className="md:hidden p-2 text-muted-fg rounded-lg hover:bg-fg/5 transition-colors"
            onClick={() => setOpen(!open)}
            aria-label="Меню"
          >
            {open ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {open && (
        <div className="md:hidden bg-bg border-t border-fg/5 px-6 py-5 space-y-4">
          {links.map(l => (
            <a
              key={l.href}
              href={l.href}
              className="block text-sm font-medium text-fg"
              onClick={() => setOpen(false)}
            >
              {l.label}
            </a>
          ))}
          <a
            href="#download"
            className="block bg-primary text-white text-sm font-semibold px-5 py-3 rounded-xl text-center"
            onClick={() => setOpen(false)}
          >
            Скачать бесплатно
          </a>
        </div>
      )}
    </nav>
  )
}
