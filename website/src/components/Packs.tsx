import { packs } from '../data/squishies'
import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

const PACK_BANNERS: Record<string, string> = {
  'squishy-foods': '/website_hero/pack_squishy_foods.png',
  'goo-and-fidgets': '/website_hero/pack_goo_fidgets.png',
  'creepy-cute-creatures': '/website_hero/pack_creepy_cute.png',
}

export function Packs() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="packs" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="Three themed packs"
          title="Each with its own vibe"
          body="Every pack has eight commons, four rares, three epics, and one legendary at the top. Same rarity ladder, totally different feel."
        />
        <div className="mt-12 space-y-8">
          {packs.map((pack, i) => (
            <PackPanel key={pack.id} pack={pack} flipped={i % 2 === 1} />
          ))}
        </div>
      </div>
    </section>
  )
}

function PackPanel({
  pack,
  flipped,
}: {
  pack: (typeof packs)[number]
  flipped: boolean
}) {
  const bannerSrc = PACK_BANNERS[pack.slug]

  const imageCluster = (
    <div
      className="relative w-full rounded-2xl overflow-hidden"
      style={{
        aspectRatio: '16 / 9',
        boxShadow: `0 24px 48px -16px ${pack.accent}55`,
        border: `1px solid ${pack.accent}40`,
      }}
    >
      {bannerSrc && (
        <img
          src={bannerSrc}
          alt={`${pack.displayName} pack hero shot`}
          loading="lazy"
          className="absolute inset-0 w-full h-full object-cover"
        />
      )}
    </div>
  )

  const copyBlock = (
    <div>
      <div
        className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold uppercase tracking-[0.2em] mb-4"
        style={{ backgroundColor: `${pack.accent}20`, color: pack.accent }}
      >
        <span aria-hidden="true">{pack.emoji}</span>
        Pack {packs.indexOf(pack) + 1} of {packs.length}
      </div>
      <h3 className="font-display text-3xl md:text-4xl font-bold mb-3">
        {pack.displayName}
      </h3>
      <p className="text-white/85 text-lg mb-6">{pack.blurb}</p>

      <div className="grid grid-cols-4 gap-3 max-w-md mb-5">
        <TierStat label="Common"    count={pack.counts.common}    color="#B0B6C3" />
        <TierStat label="Rare"      count={pack.counts.rare}      color="#7FE7FF" />
        <TierStat label="Epic"      count={pack.counts.epic}      color="#C98BFF" />
        <TierStat label="Legendary" count={pack.counts.legendary} color="#FFD36E" />
      </div>

      {pack.legendaryName && (
        <div
          className="inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-sm font-semibold"
          style={{
            backgroundColor: 'rgba(255, 211, 110, 0.14)',
            color: '#FFD36E',
            border: '1px solid rgba(255, 211, 110, 0.4)',
          }}
        >
          <span aria-hidden="true">★</span>
          Legendary chase: {pack.legendaryName}
        </div>
      )}
    </div>
  )

  return (
    <div
      className="glass-card p-8 md:p-10"
      style={{
        background: `linear-gradient(135deg, ${pack.accent}22, ${pack.accentDark}18)`,
        borderColor: `${pack.accent}55`,
      }}
    >
      <div
        className={`grid md:grid-cols-2 gap-8 items-center ${flipped ? 'md:[&>*:first-child]:order-2' : ''}`}
      >
        <div>{copyBlock}</div>
        <div>{imageCluster}</div>
      </div>
    </div>
  )
}

function TierStat({
  label,
  count,
  color,
}: {
  label: string
  count: number
  color: string
}) {
  return (
    <div className="rounded-xl px-3 py-2.5 bg-white/8 border border-white/10 text-center">
      <div
        className="font-display font-bold text-2xl leading-none"
        style={{ color }}
      >
        {count}
      </div>
      <div className="text-[0.65rem] uppercase tracking-widest text-white/65 mt-1">
        {label}
      </div>
    </div>
  )
}
