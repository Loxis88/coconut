import { ReactNode } from 'react'

interface Props {
  title: string
  updated: string
  children: ReactNode
}

export default function LegalLayout({ title, updated, children }: Props) {
  return (
    <div className="min-h-screen bg-bg text-fg font-body">
      {/* Top bar */}
      <div className="sticky top-0 bg-bg/95 backdrop-blur-md border-b border-fg/6 z-50">
        <div className="max-w-3xl mx-auto px-6 h-14 flex items-center justify-between">
          <a href="/" className="font-display text-xl font-black text-primary">МАЯК</a>
          <a
            href="/"
            className="text-sm text-muted-fg hover:text-fg transition-colors flex items-center gap-1.5"
          >
            ← На главную
          </a>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-3xl mx-auto px-6 py-16">
        <p className="font-mono text-xs text-muted-fg uppercase tracking-widest mb-3">Юридическая информация</p>
        <h1 className="font-display font-black text-fg mb-2" style={{ fontSize: 'clamp(1.8rem, 4vw, 2.8rem)' }}>
          {title}
        </h1>
        <p className="text-sm text-muted-fg mb-12 font-mono">Последнее обновление: {updated}</p>

        <div className="prose-legal">
          {children}
        </div>
      </div>

      {/* Footer minimal */}
      <div className="border-t border-fg/6 py-6">
        <p className="text-xs text-muted-fg text-center">
          © {new Date().getFullYear()} ИП Головлев Иван Александрович · ИНН 770201291441
        </p>
      </div>

      <style>{`
        .prose-legal h2 {
          font-family: var(--font-display);
          font-weight: 900;
          font-size: 1.2rem;
          color: var(--color-fg);
          margin-top: 2.5rem;
          margin-bottom: 0.75rem;
        }
        .prose-legal h3 {
          font-weight: 700;
          font-size: 1rem;
          color: var(--color-fg);
          margin-top: 1.5rem;
          margin-bottom: 0.5rem;
        }
        .prose-legal p {
          font-size: 0.9rem;
          color: var(--color-muted-fg);
          line-height: 1.75;
          margin-bottom: 0.875rem;
        }
        .prose-legal ul {
          margin-bottom: 0.875rem;
          padding-left: 1.5rem;
        }
        .prose-legal li {
          font-size: 0.9rem;
          color: var(--color-muted-fg);
          line-height: 1.75;
          margin-bottom: 0.3rem;
          list-style-type: disc;
        }
        .prose-legal strong {
          color: var(--color-fg);
          font-weight: 600;
        }
        .prose-legal a {
          color: var(--color-primary);
          text-decoration: underline;
        }
        .prose-legal .req-table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 1rem;
          font-size: 0.875rem;
        }
        .prose-legal .req-table td {
          padding: 0.5rem 0.75rem;
          border-bottom: 1px solid rgba(12,26,9,0.08);
          vertical-align: top;
        }
        .prose-legal .req-table td:first-child {
          color: var(--color-muted-fg);
          width: 45%;
          font-family: var(--font-mono);
          font-size: 0.8rem;
        }
        .prose-legal .req-table td:last-child {
          color: var(--color-fg);
          font-weight: 500;
        }
        .prose-legal .notice {
          background: var(--color-card);
          border-left: 3px solid var(--color-primary);
          padding: 1rem 1.25rem;
          border-radius: 0 12px 12px 0;
          margin: 1.25rem 0;
          font-size: 0.875rem;
          color: var(--color-muted-fg);
          line-height: 1.7;
        }
      `}</style>
    </div>
  )
}
