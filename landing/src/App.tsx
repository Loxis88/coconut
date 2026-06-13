import { useState, useEffect } from 'react'
import Navbar from './components/Navbar'
import Hero from './components/Hero'
import Trust from './components/Trust'
import Features from './components/Features'
import HowItWorks from './components/HowItWorks'
import Download from './components/Download'
import Footer from './components/Footer'
import Terms from './pages/Terms'
import Privacy from './pages/Privacy'
import Cookies from './pages/Cookies'
import Licenses from './pages/Licenses'

type Page = 'home' | 'terms' | 'privacy' | 'cookies' | 'licenses'

function getPage(): Page {
  const p = new URLSearchParams(window.location.search).get('page')
  if (p === 'terms') return 'terms'
  if (p === 'privacy') return 'privacy'
  if (p === 'cookies') return 'cookies'
  if (p === 'licenses') return 'licenses'
  return 'home'
}

export default function App() {
  const [page, setPage] = useState<Page>(getPage)

  useEffect(() => {
    const fn = () => {
      const next = getPage()
      setPage(next)
      window.scrollTo(0, 0)
    }
    window.addEventListener('popstate', fn)
    return () => window.removeEventListener('popstate', fn)
  }, [])

  if (page === 'terms')    return <Terms />
  if (page === 'privacy')  return <Privacy />
  if (page === 'cookies')  return <Cookies />
  if (page === 'licenses') return <Licenses />

  return (
    <div className="min-h-screen bg-bg text-fg font-body">
      <Navbar />
      <main>
        <Hero />
        <Trust />
        <Features />
        <HowItWorks />
        <Download />
      </main>
      <Footer />
    </div>
  )
}
