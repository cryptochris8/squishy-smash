import { useMemo, useState } from 'react'
import { packs, squishies, type Rarity, type Squishy } from '../data/squishies'
import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

type PackFilter = 'all' | (typeof packs)[number]['slug']
type RarityFilter = 'all' | Rarity

const RARITY_ORDER: Rarity[] = ['common', 'rare', 'epic', 'legendary']

export function Collection() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  const [pack, setPack] = useState<PackFilter>('all')
  const [rarity, setRarity] = useState<RarityFilter>('all')

  const filtered = useMemo(() => {
    return squishies
      .filter((s) => (pack === 'all' ? true : s.packSlug === pack))
      .filter((s) => (rarity === 'all' ? true : s.rarity === rarity))
      .sort((a, b) => {
        // Rarity descending, then name
        const rd =
          RARITY_ORDER.indexOf(b.rarity) - RARITY_ORDER.indexOf(a.rarity)
        if (rd !== 0) return rd
        return a.name.localeCompare(b.name)
      })
  }, [pack, rarity])

  return (
    <section id="collection" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="The collection"
          title="48 squishies to discover"
          body="Eight commons, four rares, three epics, and a single legendary per pack. Higher tiers unlock as you play — nothing is locked behind a paywall."
        />

        {/* Filter chips */}
        <div className="mt-10 flex flex-wrap gap-2 justify-center">
          <Chip active={pack === 'all'} onClick={() => setPack('all')}>
            All packs
          </Chip>
          {packs.map((p) => (
            <Chip
              key={p.id}
              active={pack === p.slug}
              onClick={() => setPack(p.slug as PackFilter)}
              accent={p.accent}
            >
              <span aria-hidden="true">{p.emoji}</span>
              {p.displayName}
            </Chip>
          ))}
          <span className="w-full h-0" />
          <Chip active={rarity === 'all'} onClick={() => setRarity('all')}>
            Any rarity
          </Chip>
          {RARITY_ORDER.map((r) => (
            <Chip
              key={r}
              active={rarity === r}
              onClick={() => setRarity(r)}
              accent={rarityAccent(r)}
            >
              {capitalize(r)}
            </Chip>
          ))}
        </div>

        <div className="mt-4 text-center text-sm text-white/60">
          Showing {filtered.length} of {squishies.length}
        </div>

        {/* Grid */}
        <div className="mt-8 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
          {filtered.map((s) => (
            <SquishyTile key={s.id} squishy={s} />
          ))}
        </div>
      </div>
    </section>
  )
}

function Chip({
  children,
  active,
  onClick,
  accent,
}: {
  children: React.ReactNode
  active: boolean
  onClick: () => void
  accent?: string
}) {
  return (
    <button
      onClick={onClick}
      className={`inline-flex items-center gap-2 px-4 py-2 rounded-full font-display text-sm font-semibold transition-all ${
        active
          ? 'bg-white text-bg-deep shadow-lg scale-105'
          : 'bg-white/10 text-white/80 hover:bg-white/20 border border-white/15'
      }`}
      style={
        active && accent
          ? { backgroundColor: accent, color: '#1E0E2A' }
          : undefined
      }
    >
      {children}
    </button>
  )
}

function SquishyTile({ squishy }: { squishy: Squishy }) {
  return (
    <div
      className={`group glass-card p-4 flex flex-col items-center justify-between text-center rarity-${squishy.rarity} border-2`}
    >
      <div className="relative w-full aspect-square mb-2 flex items-center justify-center">
        <img
          src={squishy.thumbnail}
          alt={squishy.name}
          className="max-w-full max-h-full object-contain transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-2"
          loading="lazy"
        />
      </div>
      <div
        className="rarity-pill mb-1"
        style={{
          backgroundColor: `${rarityAccent(squishy.rarity)}30`,
          color: rarityAccent(squishy.rarity),
          border: `1px solid ${rarityAccent(squishy.rarity)}`,
        }}
      >
        {squishy.rarity === 'legendary' ? '★ Legendary' : capitalize(squishy.rarity)}
      </div>
      <div className="font-display font-bold text-sm leading-tight">
        {squishy.name}
      </div>
    </div>
  )
}

function rarityAccent(r: Rarity): string {
  switch (r) {
    case 'common':
      return '#B0B6C3'
    case 'rare':
      return '#7FE7FF'
    case 'epic':
      return '#C98BFF'
    case 'legendary':
      return '#FFD36E'
  }
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
