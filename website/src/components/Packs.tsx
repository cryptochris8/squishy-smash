import { packs, squishies } from '../data/squishies'
import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

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
  // Pick three hero sprites from this pack to showcase — one rare,
  // one epic, and the legendary. Fall back gracefully if a tier is
  // missing.
  const packItems = squishies.filter((s) => s.packId === pack.id)
  const legendary = packItems.find((s) => s.rarity === 'legendary')
  const epic = packItems.find((s) => s.rarity === 'epic')
  const rare = packItems.find((s) => s.rarity === 'rare')
  const showcase = [rare, epic, legendary].filter(
    (s): s is NonNullable<typeof s> => Boolean(s),
  )

  const imageCluster = (
    <div className="relative w-full h-[320px] md:h-[380px]">
      {showcase.map((s, i) => {
        const size = 160 + i * 30
        const slots = [
          { top: '8%',  left: '4%',  delay: '0s',   rotate: '-6deg' },
          { top: '22%', left: '36%', delay: '1.2s', rotate: '4deg'  },
          { top: '10%', left: '68%', delay: '0.6s', rotate: '-3deg' },
        ]
        const slot = slots[i % slots.length]
        return (
          <div
            key={s.id}
            className="absolute animate-float"
            style={{
              top: slot.top,
              left: slot.left,
              width: size,
              height: size,
              animationDelay: slot.delay,
              transform: `rotate(${slot.rotate})`,
              filter: 'drop-shadow(0 18px 32px rgba(0, 0, 0, 0.35))',
            }}
          >
            <img
              src={s.sprite}
              alt={s.name}
              className="w-full h-full object-contain"
              loading="lazy"
            />
          </div>
        )
      })}
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
