import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

const PILLARS = [
  {
    icon: '\u{1F49D}',
    title: 'No ads in the core loop',
    body:
      'Every card is earnable through play. No paywalls in the album, no "watch 3 ads to continue," no dark patterns aimed at kids.',
  },
  {
    icon: '\u{1F6E1}️',
    title: 'Privacy-first',
    body:
      'No accounts, no logins, no friend-graph harvesting. Progress is saved locally on the device. Optional crash reporting carries no personal data.',
  },
  {
    icon: '\u{1F60C}',
    title: 'ASMR-adjacent calm',
    body:
      'Soft pastel palette, close-mic squish sounds, no jump-scares. Designed to feel like a fidget toy in your pocket, not a slot machine.',
  },
  {
    icon: '\u{1F36C}',
    title: 'Spam-tap-resistant',
    body:
      'Hammering the same squishy still pops and crunches — it just stops earning extra coins. Varied play feels normal; pure spam loses economic value silently.',
  },
  {
    icon: '⛰️',
    title: 'Three ways forward',
    body:
      'Each card unlocks via play (burst the matching squishy), achievements (streaks, combos, milestones), or coins (save and buy). Whichever fits the kid.',
  },
  {
    icon: '\u{1F4DD}',
    title: 'Built-in diagnostics',
    body:
      'Settings → Diagnostics shows recent in-app errors so a parent can copy-paste a clear bug report instead of "the screen looked weird that one time."',
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
