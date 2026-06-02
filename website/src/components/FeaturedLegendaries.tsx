import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

interface LegendaryEntry {
  name: string
  pack: string
  packAccent: string
  packAccentDark: string
  tagline: string
  image: string
  alt: string
}

const LEGENDARIES: LegendaryEntry[] = [
  {
    name: 'Celestial Dumpling Core',
    pack: 'Squishy Foods',
    packAccent: '#FFD36E',
    packAccentDark: '#D9A93C',
    tagline: 'A legendary core said to hold the softest light in the snack universe.',
    image: '/website_hero/hero_celestial_dumpling.png',
    alt: 'Celestial Dumpling Core — golden glowing dumpling with planetary rings',
  },
  {
    name: 'Singularity Goo Core',
    pack: 'Goo & Fidgets',
    packAccent: '#7FE7FF',
    packAccentDark: '#4FB8D6',
    tagline: 'A swirling goo singularity holding deep cyan light in perfect balance.',
    image: '/website_hero/hero_singularity_goo.png',
    alt: 'Singularity Goo Core — aurora-cyan glowing goo with swirling inner patterns',
  },
  {
    name: 'Mythic Plush Familiar',
    pack: 'Creepy-Cute Creatures',
    packAccent: '#C98BFF',
    packAccentDark: '#9E5FD9',
    tagline: 'A plush familiar wrapped in soft moonlit magic, watching gently.',
    image: '/website_hero/hero_mythic_plush.png',
    alt: 'Mythic Plush Familiar — cat-plush creature with ethereal violet glow',
  },
]

export function FeaturedLegendaries() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="legendaries" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="Meet the legendaries"
          title="Three legends, one per pack."
          body="At the top of every pack waits a single Legendary — the chase card that rewards a full album hunt. Each one shines with its pack's signature palette."
        />

        <div className="mt-12 grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {LEGENDARIES.map((leg) => (
            <LegendaryCard key={leg.name} entry={leg} />
          ))}
        </div>
      </div>
    </section>
  )
}

function LegendaryCard({ entry }: { entry: LegendaryEntry }) {
  return (
    <div
      className="glass-card overflow-hidden flex flex-col"
      style={{
        background: `linear-gradient(160deg, ${entry.packAccent}22, ${entry.packAccentDark}10)`,
        borderColor: `${entry.packAccent}55`,
        boxShadow: `0 12px 36px -16px ${entry.packAccent}55`,
      }}
    >
      <div className="relative aspect-square w-full overflow-hidden">
        <img
          src={entry.image}
          alt={entry.alt}
          loading="lazy"
          className="absolute inset-0 w-full h-full object-cover"
        />
        <div
          className="absolute top-3 right-3 px-3 py-1 rounded-full text-[10px] font-display font-bold uppercase tracking-widest backdrop-blur-md"
          style={{
            backgroundColor: 'rgba(0, 0, 0, 0.4)',
            color: entry.packAccent,
            border: `1px solid ${entry.packAccent}55`,
          }}
        >
          ★ Legendary
        </div>
      </div>
      <div className="p-5 flex flex-col gap-2">
        <div
          className="text-[10px] font-display font-bold uppercase tracking-widest"
          style={{ color: entry.packAccent }}
        >
          {entry.pack}
        </div>
        <h3 className="font-display text-xl font-bold leading-tight">
          {entry.name}
        </h3>
        <p className="text-white/75 text-sm leading-relaxed">{entry.tagline}</p>
      </div>
    </div>
  )
}
