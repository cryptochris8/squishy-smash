import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

const PILLARS = [
  {
    icon: '\u{1F49D}',
    title: 'No ads, no IAP',
    body:
      'Every squishy is earnable through play. No paywalls, no "watch 3 ads to continue," no dark patterns aimed at kids.',
  },
  {
    icon: '\u{1F6E1}️',
    title: 'Privacy-first',
    body:
      'No personalized tracking. Apple App Tracking Transparency respected. Kid-safe analytics only — no social login, no friend-graph harvesting.',
  },
  {
    icon: '\u{1F60C}',
    title: 'ASMR-adjacent calm',
    body:
      'Soft pastel palette, close-mic squish sounds, no jump-scares. Designed to feel like a fidget toy in your pocket, not a slot machine.',
  },
  {
    icon: '⛰️',
    title: 'Earned rarity',
    body:
      'Legendaries require real engagement — roughly 20+ reveals per pack before they can even spawn. Pity logic guarantees committed players eventually get them.',
  },
]

export function ForParents() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="parents" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="For parents"
          title="Built the way we'd want our own kids' games built."
          body="We took the parts of mobile gaming we're tired of defending and left them out."
        />
        <div className="mt-12 grid md:grid-cols-2 gap-5">
          {PILLARS.map((p) => (
            <div
              key={p.title}
              className="glass-card p-6 flex gap-5 items-start"
            >
              <div
                className="w-12 h-12 shrink-0 rounded-2xl bg-white/10 flex items-center justify-center text-2xl"
                aria-hidden="true"
              >
                {p.icon}
              </div>
              <div>
                <h3 className="font-display text-xl font-bold mb-2">{p.title}</h3>
                <p className="text-white/80 leading-relaxed">{p.body}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
