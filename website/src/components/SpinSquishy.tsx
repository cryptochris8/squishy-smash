import { useState } from 'react'
import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

interface SpinEntry {
  name: string
  slug: string
  pack: string
  packAccent: string
  packAccentDark: string
  tagline: string
}

const SPINNABLES: SpinEntry[] = [
  {
    name: 'Soft Dumpling',
    slug: 'soft_dumpling',
    pack: 'Squishy Foods',
    packAccent: '#FFD36E',
    packAccentDark: '#D9A93C',
    tagline: 'A warm, jiggly favorite — steamer basket and all.',
  },
  {
    name: 'Goo Ball',
    slug: 'goo_ball',
    pack: 'Goo & Fidgets',
    packAccent: '#7FE7FF',
    packAccentDark: '#4FB8D6',
    tagline: 'Glossy, bouncy, and mid-splash from every angle.',
  },
  {
    name: 'Blushy Bun Bunny',
    slug: 'blushy_bun_bunny',
    pack: 'Creepy-Cute Creatures',
    packAccent: '#C98BFF',
    packAccentDark: '#9E5FD9',
    tagline: 'Floppy ears, pink blush, impossibly soft.',
  },
  {
    name: 'Celestial Dumpling Core',
    slug: 'celestial_dumpling_core',
    pack: 'Squishy Foods',
    packAccent: '#FFD36E',
    packAccentDark: '#D9A93C',
    tagline: 'The legendary core — now spinning with its rings.',
  },
  {
    name: 'Singularity Goo Core',
    slug: 'singularity_goo_core',
    pack: 'Goo & Fidgets',
    packAccent: '#7FE7FF',
    packAccentDark: '#4FB8D6',
    tagline: 'A swirling goo singularity you can turn in your hands.',
  },
  {
    name: 'Mythic Plush Familiar',
    slug: 'mythic_plush_familiar',
    pack: 'Creepy-Cute Creatures',
    packAccent: '#C98BFF',
    packAccentDark: '#9E5FD9',
    tagline: 'Halo, cape, and moonlit magic in full 3D.',
  },
]

export function SpinSquishy() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  const [active, setActive] = useState(SPINNABLES[0])

  return (
    <section id="spin" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="Spin a squishy"
          title="Pick one up. Give it a spin."
          body="Every card in the game is a real 3D squishy. Drag to spin, sit back and watch it twirl — these are the exact characters you collect in the app."
        />

        <div className="mt-12 grid lg:grid-cols-[1fr_280px] gap-6 items-start">
          <div
            className="glass-card overflow-hidden"
            style={{
              background: `linear-gradient(160deg, ${active.packAccent}22, ${active.packAccentDark}10)`,
              borderColor: `${active.packAccent}55`,
              boxShadow: `0 12px 36px -16px ${active.packAccent}55`,
            }}
          >
            <model-viewer
              key={active.slug}
              src={`/models/${active.slug}.glb`}
              poster={`/models/posters/${active.slug}.webp`}
              alt={`${active.name} — interactive 3D squishy`}
              camera-controls
              auto-rotate
              auto-rotate-delay="1200"
              rotation-per-second="24deg"
              shadow-intensity="1"
              shadow-softness="0.8"
              interaction-prompt="auto"
              touch-action="pan-y"
              loading="lazy"
              exposure="1.1"
              style={{ width: '100%', height: 'min(60vh, 520px)' }}
            />
            <div className="p-5 flex flex-col gap-1">
              <div
                className="text-[10px] font-display font-bold uppercase tracking-widest"
                style={{ color: active.packAccent }}
              >
                {active.pack}
              </div>
              <h3 className="font-display text-xl font-bold leading-tight">
                {active.name}
              </h3>
              <p className="text-white/75 text-sm leading-relaxed">
                {active.tagline}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-3 lg:grid-cols-2 gap-3">
            {SPINNABLES.map((s) => (
              <button
                key={s.slug}
                type="button"
                onClick={() => setActive(s)}
                aria-pressed={active.slug === s.slug}
                aria-label={`Spin ${s.name}`}
                className="glass-card p-2 flex flex-col items-center gap-1 transition-transform hover:scale-[1.04] focus-visible:scale-[1.04]"
                style={{
                  borderColor:
                    active.slug === s.slug ? s.packAccent : `${s.packAccent}33`,
                  boxShadow:
                    active.slug === s.slug
                      ? `0 8px 24px -10px ${s.packAccent}aa`
                      : 'none',
                }}
              >
                <img
                  src={`/models/posters/${s.slug}.webp`}
                  alt=""
                  loading="lazy"
                  className="w-full aspect-square object-cover rounded-xl"
                />
                <span className="text-[11px] font-display font-semibold leading-tight text-center text-white/85">
                  {s.name}
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
