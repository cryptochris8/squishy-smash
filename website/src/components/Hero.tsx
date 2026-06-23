import { APP_STORE_URL, ROBLOX_GAME_URL, AMAZON_BOOK_URL } from '../constants/links'

/* Six hero-section companions using NBP-generated hero shots from
 * assets/website_hero/. Balanced 2-2-2 across the three packs, with a
 * mix of Rare / Epic / Legendary tiers. The Legendary (Celestial
 * Dumpling Core) sits in the load-bearing slot (index 3) per the
 * FloatingSquishy positioning. */
const HERO_COMPANIONS: Array<{ name: string; image: string }> = [
  { name: 'Sparkle Mochi',
    image: '/website_hero/hero_011_sparkle_mochi.png' },         // Foods Rare
  { name: 'Moon Bat Blob',
    image: '/website_hero/hero_042_moon_bat_blob.png' },         // Creepy-Cute Rare
  { name: 'Glitter Goo Ball',
    image: '/website_hero/hero_025_glitter_goo_ball.png' },      // Goo Rare
  { name: 'Celestial Dumpling Core',
    image: '/website_hero/hero_celestial_dumpling.png' },        // Foods Legendary (hero slot)
  { name: 'Mythic Plush Familiar',
    image: '/website_hero/hero_mythic_plush.png' },              // Creepy-Cute Legendary
  { name: 'Aurora Stretch Cube',
    image: '/website_hero/hero_030_aurora_stretch_cube.png' },   // Goo Epic
]

export function Hero() {
  const companions = HERO_COMPANIONS

  return (
    <header id="top" className="relative z-10 pt-32 pb-20 px-6">
      <div className="max-w-6xl mx-auto grid lg:grid-cols-[1.15fr_1fr] gap-12 items-center">
        {/* Copy + CTA */}
        <div className="relative">
          <div className="inline-flex items-center gap-2 glass-card px-4 py-2 mb-6 text-xs font-bold tracking-wider uppercase text-cream-300 animate-pop">
            <span aria-hidden="true">✨</span>
            <span>Now on Roblox, iOS + books</span>
          </div>

          <h1 className="font-display text-5xl sm:text-6xl lg:text-7xl leading-[0.95] mb-6 animate-fade-in-up">
            <span className="rainbow-text">Squishy Smash</span>
          </h1>

          <p className="text-xl lg:text-2xl text-white/90 max-w-xl mb-3 animate-fade-in-up-delayed">
            Tap. Squish. Pop. Collect.
          </p>
          <p className="text-base lg:text-lg text-white/75 max-w-xl mb-8 animate-fade-in-up-delayed">
            One cozy, kawaii squishy world. Play it <strong>free on Roblox</strong>,
            collect on the <strong>App Store</strong>, and read the{' '}
            <strong>storybooks</strong> — adorable friends to squish, discover, and
            collect across every platform. Zero scary stuff, ever.
          </p>

          <div className="flex flex-wrap gap-3 items-center animate-fade-in-up-delayed">
            <a
              href={ROBLOX_GAME_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="glow-btn inline-flex items-center gap-2"
            >
              <RobloxIcon />
              <span>Play free on Roblox</span>
            </a>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="glow-btn inline-flex items-center gap-2"
            >
              <AppleLogo />
              <span>Get the iOS app</span>
            </a>
            <a href="#collection" className="glow-btn ghost">
              See the collection
            </a>
          </div>

          {/* Companion book CTA — secondary surface so it doesn't
              compete with the app install. Live on Amazon since
              2026-05-16. */}
          <a
            href={AMAZON_BOOK_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-5 inline-flex items-center gap-2 text-sm text-white/75 hover:text-cream-300 transition-colors animate-fade-in-up-delayed"
          >
            <BookIcon />
            <span>
              <span className="font-bold text-cream-300">New:</span>{' '}
              the paperback book is live on Amazon
            </span>
            <span aria-hidden="true">→</span>
          </a>

          <div className="mt-10 flex items-center gap-5 text-sm text-white/70">
            <Stat number="48" label="cards" />
            <span className="h-8 w-px bg-white/20" />
            <Stat number="3" label="packs" />
            <span className="h-8 w-px bg-white/20" />
            <Stat number="3" label="unlock paths" />
          </div>
        </div>

        {/* Floating squishy companions */}
        <div className="relative h-[420px] lg:h-[520px]">
          {companions.map((s, i) => (
            <FloatingSquishy key={s.name} squishy={s} index={i} />
          ))}
        </div>
      </div>
    </header>
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

function BookIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="w-4 h-4"
      aria-hidden="true"
    >
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
  )
}

function Stat({ number, label }: { number: string; label: string }) {
  return (
    <div>
      <div className="font-display font-bold text-2xl text-cream-300 leading-none">
        {number}
      </div>
      <div className="uppercase text-[0.7rem] tracking-widest">{label}</div>
    </div>
  )
}

function FloatingSquishy({
  squishy,
  index,
}: {
  squishy: { name: string; image: string }
  index: number
}) {
  // Hand-placed positions + scales so the cluster feels intentional
  // rather than random. 6 slots — top L, top R, mid L, mid R (hero),
  // bottom L, bottom R.
  const slots: {
    top: string
    left: string
    size: number
    animClass: string
    z: number
  }[] = [
    { top: '3%',  left: '3%',  size: 120, animClass: 'animate-float',         z: 2 },
    { top: '10%', left: '62%', size: 140, animClass: 'animate-float-slow',    z: 3 },
    { top: '38%', left: '15%', size: 160, animClass: 'animate-float-delayed', z: 4 },
    { top: '36%', left: '50%', size: 220, animClass: 'animate-float',         z: 6 },
    { top: '72%', left: '2%',  size: 130, animClass: 'animate-float-slower',  z: 3 },
    { top: '68%', left: '66%', size: 150, animClass: 'animate-float-slow',    z: 4 },
  ]
  const slot = slots[index % slots.length]
  const isHero = index === 3
  return (
    <div
      className={`absolute ${slot.animClass}`}
      style={{
        top: slot.top,
        left: slot.left,
        width: slot.size,
        height: slot.size,
        zIndex: slot.z,
        filter: isHero
          ? 'drop-shadow(0 20px 40px rgba(255, 211, 110, 0.6))'
          : 'drop-shadow(0 12px 24px rgba(0, 0, 0, 0.3))',
      }}
    >
      <img
        src={squishy.image}
        alt={squishy.name}
        className="w-full h-full object-contain"
        loading="eager"
      />
    </div>
  )
}
