import { useEffect, useState } from 'react'

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
        <a href="#join" className="glow-btn text-sm !py-2 !px-5">
          Join TestFlight
        </a>
      </div>
    </nav>
  )
}
