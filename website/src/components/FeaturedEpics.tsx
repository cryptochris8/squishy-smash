import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

interface EpicEntry {
  name: string
  pack: string
  packAccent: string
  packAccentDark: string
  tagline: string
  image: string
  alt: string
}

const EPICS: EpicEntry[] = [
  {
    name: 'Galaxy Dumpling',
    pack: 'Squishy Foods',
    packAccent: '#FFD36E',
    packAccentDark: '#D9A93C',
    tagline: 'A starlit dumpling carrying a tiny cosmos in its curl.',
    image: '/website_hero/hero_013_galaxy_dumpling.png',
    alt: 'Galaxy Dumpling — cosmic purple-blue dumpling with constellation freckles',
  },
  {
    name: 'Aurora Stretch Cube',
    pack: 'Goo & Fidgets',
    packAccent: '#7FE7FF',
    packAccentDark: '#4FB8D6',
    tagline: 'An iridescent goo cube that bends light into a slow rainbow.',
    image: '/website_hero/hero_030_aurora_stretch_cube.png',
    alt: 'Aurora Stretch Cube — iridescent rainbow goo cube',
  },
  {
    name: 'Arcane Wobble Kitty',
    pack: 'Creepy-Cute Creatures',
    packAccent: '#C98BFF',
    packAccentDark: '#9E5FD9',
    tagline: 'A mystical kitten whose wobble bends moonlight.',
    image: '/website_hero/hero_046_arcane_wobble_kitty.png',
    alt: 'Arcane Wobble Kitty — magical kitten with violet runes and aurora glow',
  },
]

export function FeaturedEpics() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="epics" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="And just below — the epics"
          title="Three epics, one shy of legendary."
          body="The tier right below Legendary. Three per pack, each with its own loud little personality. Here are the three we keep coming back to."
        />

        <div className="mt-12 grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {EPICS.map((e) => (
            <EpicCard key={e.name} entry={e} />
          ))}
        </div>
      </div>
    </section>
  )
}

function EpicCard({ entry }: { entry: EpicEntry }) {
  return (
    <div
      className="glass-card overflow-hidden flex flex-col"
      style={{
        background: `linear-gradient(160deg, ${entry.packAccent}1A, ${entry.packAccentDark}0C)`,
        borderColor: `${entry.packAccent}40`,
        boxShadow: `0 12px 36px -16px ${entry.packAccent}40`,
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
          Epic
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
