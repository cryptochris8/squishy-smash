import { useReveal } from '../hooks/useReveal'
import { APP_STORE_URL } from '../constants/links'

export function JoinCTA() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()

  return (
    <section id="join" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-3xl mx-auto text-center reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <div className="glass-dark p-10 md:p-14 relative overflow-hidden animate-pulse-glow">
          <div
            className="absolute -top-20 -right-20 w-72 h-72 rounded-full opacity-30 blur-3xl"
            style={{ background: 'radial-gradient(circle, #FFD36E, transparent 70%)' }}
            aria-hidden="true"
          />
          <div
            className="absolute -bottom-20 -left-20 w-72 h-72 rounded-full opacity-30 blur-3xl"
            style={{ background: 'radial-gradient(circle, #C98BFF, transparent 70%)' }}
            aria-hidden="true"
          />

          <div className="relative">
            <div className="inline-block font-display text-xs font-bold uppercase tracking-[0.25em] text-cream-300 bg-white/10 px-3 py-1.5 rounded-full mb-6">
              Live on the App Store
            </div>
            <h2 className="font-display text-4xl md:text-5xl font-bold mb-4">
              Tap. Squish. Pop.
            </h2>
            <p className="text-lg text-white/80 max-w-lg mx-auto mb-8">
              The squishies are loose. Forty-eight to collect across three
              packs. Your first squish is one tap away.
            </p>

            <div className="flex flex-col sm:flex-row gap-3 items-center justify-center">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="glow-btn inline-flex items-center gap-2"
              >
                <AppleLogo />
                <span>Download on the App Store</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

function AppleLogo() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  )
}
