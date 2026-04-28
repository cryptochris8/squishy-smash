import { useEffect, useState } from 'react'
import { APP_STORE_URL } from '../constants/links'

export function Nav() {
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <nav
      className={`nav-glass fixed top-0 left-0 right-0 z-50 px-6 transition-all ${
        scrolled ? 'py-2.5' : 'py-4'
      }`}
    >
      <div className="max-w-6xl mx-auto flex items-center justify-between">
        <a href="#top" className="flex items-center gap-2 group">
          <img
            src="/branding/squishy_smash_icon_bunny_v1.png"
            alt="Squishy Smash"
            className="w-10 h-10 rounded-2xl transition-transform group-hover:scale-110 group-hover:rotate-6"
          />
          <span className="font-display text-lg font-bold tracking-tight hidden sm:inline">
            Squishy Smash
          </span>
        </a>
        <div className="hidden md:flex items-center gap-6 text-sm font-semibold text-white/90">
          <a href="#core-loop" className="hover:text-cream-300 transition-colors">How it plays</a>
          <a href="#collection" className="hover:text-cream-300 transition-colors">Collection</a>
          <a href="#packs" className="hover:text-cream-300 transition-colors">Packs</a>
          <a href="#parents" className="hover:text-cream-300 transition-colors">For parents</a>
        </div>
        <a
          href={APP_STORE_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="glow-btn text-sm !py-2 !px-5 inline-flex items-center gap-2"
        >
          <AppleLogo />
          <span>Download</span>
        </a>
      </div>
    </nav>
  )
}

function AppleLogo() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className="w-4 h-4"
      aria-hidden="true"
    >
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  )
}
