import { useReveal } from '../hooks/useReveal'

const STEPS = [
  {
    icon: '👆',
    title: 'Squish',
    body: 'Tap or drag to compress — every squishy has its own deform, elasticity, and burst threshold. The feedback feels different for dumplings, jellies, goos, and creatures.',
    accent: 'from-pink-300 to-pink-400',
  },
  {
    icon: '🔥',
    title: 'Combo',
    body: 'Keep the rhythm going. Streak 3 → starter. 6 → stronger. 10 → reveal-ready. 15+ → mega. The HUD bar shifts color each milestone.',
    accent: 'from-cream-300 to-pink-300',
  },
  {
    icon: '✨',
    title: 'Reveal',
    body: 'Rare bursts swap the skybox and flash a bloom overlay. Epics push it harder. Legendaries freeze-frame with a held glow — worth waiting for.',
    accent: 'from-lavender-300 to-jelly-300',
  },
]

export function CoreLoop() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="core-loop" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="The core loop"
          title="Three beats. Endless replay."
          body="Every session is the same satisfying shape: feel the squish, build the rhythm, chase the reveal."
        />
        <div className="mt-12 grid md:grid-cols-3 gap-6">
          {STEPS.map((step, i) => (
            <div
              key={step.title}
              className="glass-card p-8 relative"
              style={{ animationDelay: `${i * 0.1}s` }}
            >
              <div
                className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${step.accent} flex items-center justify-center text-3xl mb-5 shadow-lg`}
                aria-hidden="true"
              >
                {step.icon}
              </div>
              <div className="flex items-baseline gap-3 mb-3">
                <span className="font-display text-xs font-bold uppercase tracking-widest text-white/50">
                  {String(i + 1).padStart(2, '0')}
                </span>
                <h3 className="font-display text-2xl font-bold">{step.title}</h3>
              </div>
              <p className="text-white/80 leading-relaxed">{step.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export function SectionHeading({
  kicker,
  title,
  body,
  align = 'center',
}: {
  kicker?: string
  title: string
  body?: string
  align?: 'center' | 'left'
}) {
  const wrap = align === 'center' ? 'text-center mx-auto' : 'text-left'
  return (
    <div className={`${wrap} max-w-2xl`}>
      {kicker && (
        <div className="inline-block font-display text-xs font-bold uppercase tracking-[0.2em] text-cream-300 bg-white/10 px-3 py-1.5 rounded-full mb-4">
          {kicker}
        </div>
      )}
      <h2 className="font-display text-4xl sm:text-5xl font-bold leading-tight mb-4">
        {title}
      </h2>
      {body && <p className="text-lg text-white/80">{body}</p>}
    </div>
  )
}
