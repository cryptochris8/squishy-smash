import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'
import { ROBLOX_GAME_URL } from '../constants/links'

/* "Now on Roblox" launch section. Showcases the 3D game (The Lost
 * Sparkle) with a real in-game screenshot, distinct from the mobile
 * tap game above it. Image lives at public/roblox-lost-sparkle.jpg. */
const FEATURES = [
  'Three squishy lands — Pudding Hills, Goo Coast & Moonlit Hollow',
  'Wake sleepy friends, ride the Sparkle Express, decorate your room',
  'Collect all 48 friends to restore the lost sparkle',
  'Free to play — Sparkle Capsules are always free',
]

export function RobloxSection() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="roblox" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="New — now on Roblox"
          title="Step inside the squishy world."
          body="Squishy Smash: The Lost Sparkle is live on Roblox — a free 3D adventure across three pastel lands. Same friends, a whole world to explore."
        />

        <div className="mt-12 grid lg:grid-cols-[1.5fr_1fr] gap-8 items-center">
          {/* Screenshot — links straight to the game */}
          <a
            href={ROBLOX_GAME_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="glass-card overflow-hidden block group"
            aria-label="Play Squishy Smash: The Lost Sparkle on Roblox"
          >
            <div className="relative aspect-video w-full overflow-hidden">
              <img
                src="/roblox-lost-sparkle.jpg"
                alt="Squishy Smash: The Lost Sparkle on Roblox — a pastel candy world with the Sparkle Wheel ferris wheel under a blue sky"
                loading="lazy"
                className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
              />
              <div className="absolute bottom-3 left-3 inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-display font-bold backdrop-blur-md bg-black/40 text-white">
                <RobloxIcon />
                <span>Play on Roblox</span>
              </div>
            </div>
          </a>

          {/* Copy + CTA */}
          <div>
            <ul className="space-y-3 mb-8">
              {FEATURES.map((f) => (
                <li key={f} className="flex items-start gap-3 text-white/85">
                  <span className="mt-1 text-cream-300" aria-hidden="true">
                    ✦
                  </span>
                  <span className="leading-relaxed">{f}</span>
                </li>
              ))}
            </ul>
            <a
              href={ROBLOX_GAME_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="glow-btn inline-flex items-center gap-2"
            >
              <RobloxIcon />
              <span>Play free on Roblox</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}

function RobloxIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M21 6H3c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zM11 13H8v3H6v-3H3v-2h3V8h2v3h3v2zm4.5 2a1.5 1.5 0 110-3 1.5 1.5 0 010 3zm4-3a1.5 1.5 0 110-3 1.5 1.5 0 010 3z" />
    </svg>
  )
}
