import { Link, useParams } from 'react-router-dom'
import { packs, squishies, type Rarity } from '../data/squishies'

// Map pack slug → hero shot card numbers for the 8 elite-tier characters
// (4 rares + 3 epics + 1 legendary). Order in the array is preserved on
// the gallery grid.
const ELITE_CARD_NUMS: Record<string, number[]> = {
  'squishy-foods':         [9, 10, 11, 12, 13, 14, 15, 16],
  'goo-and-fidgets':       [25, 26, 27, 28, 29, 30, 31, 32],
  'creepy-cute-creatures': [41, 42, 43, 44, 45, 46, 47, 48],
}

const RARITY_ACCENT: Record<Rarity, string> = {
  common:    '#B0B6C3',
  rare:      '#7FE7FF',
  epic:      '#C98BFF',
  legendary: '#FFD36E',
}

function _slug(name: string) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '')
}

function _heroShotPath(cardNum: number, name: string): string {
  // The 3 Legendaries use the original short names; Rares/Epics use the
  // numbered scheme from gen_elite_tier.py.
  if (cardNum === 16) return '/website_hero/hero_celestial_dumpling.png'
  if (cardNum === 32) return '/website_hero/hero_singularity_goo.png'
  if (cardNum === 48) return '/website_hero/hero_mythic_plush.png'
  return `/website_hero/hero_${cardNum.toString().padStart(3, '0')}_${_slug(name)}.png`
}

export function PackPage() {
  const { slug } = useParams<{ slug: string }>()
  const pack = packs.find((p) => p.slug === slug)
  const cardNums = slug ? ELITE_CARD_NUMS[slug] : undefined

  if (!pack || !cardNums) {
    return (
      <section className="relative z-10 pt-32 pb-20 px-6 min-h-[60vh]">
        <div className="max-w-3xl mx-auto text-center">
          <h1 className="font-display text-4xl font-bold mb-4">Pack not found.</h1>
          <p className="text-white/80 mb-8">
            We couldn&apos;t find the pack you were looking for.
          </p>
          <Link to="/" className="glow-btn inline-block">Back to the home page</Link>
        </div>
      </section>
    )
  }

  // Resolve the 8 elite-tier characters by joining card numbers to squishy data
  const eliteSquishies = cardNums
    .map((num) => {
      const cardNumStr = `${num.toString().padStart(3, '0')}/048`
      return squishies.find((s) => s.cardNumber === cardNumStr)
    })
    .filter((s): s is NonNullable<typeof s> => Boolean(s))

  return (
    <section className="relative z-10 pt-32 pb-24 px-6">
      <div className="max-w-6xl mx-auto">
        {/* Back link */}
        <Link
          to="/#packs"
          className="inline-flex items-center gap-1.5 text-sm text-white/70 hover:text-cream-300 transition-colors mb-6"
        >
          <span aria-hidden="true">←</span>
          <span>Back to all packs</span>
        </Link>

        {/* Header */}
        <div
          className="rounded-3xl p-8 md:p-12 mb-12 glass-card"
          style={{
            background: `linear-gradient(135deg, ${pack.accent}22, ${pack.accentDark}18)`,
            borderColor: `${pack.accent}55`,
          }}
        >
          <div
            className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-[0.2em] mb-4"
            style={{ backgroundColor: `${pack.accent}20`, color: pack.accent }}
          >
            <span aria-hidden="true">{pack.emoji}</span>
            Pack {packs.findIndex((p) => p.slug === slug) + 1} of {packs.length}
          </div>
          <h1 className="font-display text-4xl md:text-5xl font-bold mb-4">
            {pack.displayName}
          </h1>
          <p className="text-white/85 text-lg max-w-2xl mb-6">{pack.blurb}</p>
          <div className="text-white/75 text-sm">
            8 elite-tier characters shown below — 4 rares, 3 epics, and the legendary chase.
          </div>
        </div>

        {/* Elite gallery */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {eliteSquishies.map((s, i) => {
            const cardNum = cardNums[i]
            const heroSrc = _heroShotPath(cardNum, s.name)
            const accent = RARITY_ACCENT[s.rarity]
            return (
              <div
                key={s.id}
                className="glass-card overflow-hidden flex flex-col"
                style={{
                  borderColor: `${accent}55`,
                  boxShadow: `0 12px 36px -16px ${accent}55`,
                }}
              >
                <div className="relative aspect-square w-full overflow-hidden">
                  <img
                    src={heroSrc}
                    alt={`${s.name} — ${s.rarity}`}
                    loading="lazy"
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                  <div
                    className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full text-[10px] font-display font-bold uppercase tracking-widest backdrop-blur-md"
                    style={{
                      backgroundColor: 'rgba(0, 0, 0, 0.45)',
                      color: accent,
                      border: `1px solid ${accent}55`,
                    }}
                  >
                    {s.rarity === 'legendary' ? '★ Legendary' : s.rarity[0].toUpperCase() + s.rarity.slice(1)}
                  </div>
                </div>
                <div className="p-4">
                  <h3 className="font-display text-lg font-bold leading-tight">{s.name}</h3>
                  <div className="text-[10px] uppercase tracking-widest text-white/55 mt-1">
                    {s.cardNumber}
                  </div>
                </div>
              </div>
            )
          })}
        </div>

        {/* Footer CTA */}
        <div className="mt-12 text-center">
          <Link to="/#collection" className="glow-btn ghost inline-block">
            See all 48 cards
          </Link>
        </div>
      </div>
    </section>
  )
}
