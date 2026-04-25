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
        // Sort by card_number when available (gives the canonical
        // 001 → 048 order), else fall back to rarity-then-name so
        // un-mapped entries still group nicely.
        if (a.cardNumber && b.cardNumber) {
          return a.cardNumber.localeCompare(b.cardNumber)
        }
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
          title="48 cards. Three ways to unlock."
          body="Eight commons, four rares, three epics, and a single legendary per pack. Earn each card through play, save coins to buy it, or unlock it through achievement rewards. Whichever fits your style — the album fills."
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

        <div
          className="mt-4 text-center text-sm text-white/60"
          aria-live="polite"
        >
          Showing {filtered.length} of {squishies.length}
        </div>

        {/* Grid — taller, card-shaped tiles to honor the 3:4 aspect of
            the WebP card art. Fewer columns at small breakpoints so the
            art doesn't scrunch. */}
        <div className="mt-8 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 md:gap-5">
          {filtered.map((s) => (
            <CardTile key={s.id} squishy={s} />
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
  // ARIA: announce filter state so screen-reader users know which
  // chip is currently active without inspecting visual styling.
  return (
    <button
      onClick={onClick}
      aria-pressed={active}
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

function CardTile({ squishy }: { squishy: Squishy }) {
  const accent = rarityAccent(squishy.rarity)
  // Prefer the full card WebP (richer art shipped in v0.1.1); fall
  // back to the in-game thumbnail for any squishy without a card
  // mapping. Both code paths render at the same 3:4 aspect.
  const imageSrc = squishy.cardImage ?? squishy.thumbnail
  const usingCardArt = squishy.cardImage !== null
  return (
    <div
      className={`group glass-card flex flex-col rarity-${squishy.rarity} border-2 overflow-hidden`}
      style={{
        borderColor: accent + '60',
        boxShadow: `0 8px 32px -10px ${accent}40`,
      }}
    >
      <div className="relative aspect-[3/4] w-full bg-black/20">
        <img
          src={imageSrc}
          alt={squishy.name}
          loading="lazy"
          className={`absolute inset-0 w-full h-full transition-transform duration-300 group-hover:scale-105 ${
            usingCardArt ? 'object-cover' : 'object-contain p-3'
          }`}
        />
        {/* Card number floats top-right when present — quick visual
            cue for "this is part of the 48-card collection." */}
        {squishy.cardNumber && (
          <div className="absolute top-2 right-2 px-2 py-0.5 text-[10px] font-display font-bold tracking-wider rounded-full bg-black/60 text-white/80 backdrop-blur-sm">
            {squishy.cardNumber}
          </div>
        )}
      </div>
      <div className="p-3 flex flex-col items-center text-center gap-1">
        <div
          className="rarity-pill"
          style={{
            backgroundColor: accent + '30',
            color: accent,
            border: `1px solid ${accent}`,
          }}
        >
          {squishy.rarity === 'legendary'
            ? '★ Legendary'
            : capitalize(squishy.rarity)}
        </div>
        <div className="font-display font-bold text-sm leading-tight">
          {squishy.name}
        </div>
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
