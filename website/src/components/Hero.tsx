import { squishies } from '../data/squishies'

/* Six hero-companion sprites — hand-picked to show off tier variety:
 * two commons, two rares, the three legendaries feel too "loud" for
 * every visit so we pick one plus a pack-accent epic. */
const HERO_COMPANIONS = [
  'blushy_bun_bunny',        // common creepy-cute bunny
  'peach_mochi',             // common food
  'rainbow_jelly_bun',       // rare food
  'glitter_goo_ball',        // rare goo
  'crystal_mochi',           // epic food
  'celestial_dumpling_core', // legendary hero
]

export function Hero() {
  const companions = HERO_COMPANIONS
    .map((id) => squishies.find((s) => s.id === id))
    .filter((s): s is NonNullable<typeof s> => s !== undefined)

  return (
    <header id="top" className="relative z-10 pt-32 pb-20 px-6">
      <div className="max-w-6xl mx-auto grid lg:grid-cols-[1.15fr_1fr] gap-12 items-center">
        {/* Copy + CTA */}
        <div className="relative">
          <div className="inline-flex items-center gap-2 glass-card px-4 py-2 mb-6 text-xs font-bold tracking-wider uppercase text-cream-300 animate-pop">
            <span aria-hidden="true">✨</span>
            <span>Soft-launch on TestFlight</span>
          </div>

          <h1 className="font-display text-5xl sm:text-6xl lg:text-7xl leading-[0.95] mb-6 animate-fade-in-up">
            <span className="rainbow-text">Squishy Smash</span>
          </h1>

          <p className="text-xl lg:text-2xl text-white/90 max-w-xl mb-3 animate-fade-in-up-delayed">
            Tap. Squish. Pop. Repeat.
          </p>
          <p className="text-base lg:text-lg text-white/75 max-w-xl mb-8 animate-fade-in-up-delayed">
            A cozy kawaii tap game. <strong>48 collectible squishies</strong>{' '}
            across three pastel packs. Satisfying combos, dreamy reveals, zero
            scary stuff.
          </p>

          <div className="flex flex-wrap gap-3 items-center animate-fade-in-up-delayed">
            <a href="#join" className="glow-btn">
              Join TestFlight
              <span aria-hidden="true">→</span>
            </a>
            <a href="#collection" className="glow-btn ghost">
              See the collection
            </a>
          </div>

          <div className="mt-10 flex items-center gap-5 text-sm text-white/70">
            <Stat number="48" label="squishies" />
            <span className="h-8 w-px bg-white/20" />
            <Stat number="3" label="packs" />
            <span className="h-8 w-px bg-white/20" />
            <Stat number="4" label="rarity tiers" />
          </div>
        </div>

        {/* Floating squishy companions */}
        <div className="relative h-[420px] lg:h-[520px]">
          {companions.map((s, i) => (
            <FloatingSquishy key={s.id} squishy={s} index={i} />
          ))}
        </div>
      </div>
    </header>
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
  squishy: (typeof squishies)[number]
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
        src={squishy.sprite}
        alt={squishy.name}
        className="w-full h-full object-contain"
        loading="eager"
      />
    </div>
  )
}
