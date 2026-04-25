import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'

const HIGHLIGHTS = [
  {
    icon: '🎴',
    title: 'Three ways to unlock',
    body:
      'Every card has three independent paths: earn it through play, save coins to buy it, or claim it as an achievement reward. Whichever fits your style.',
    accent: 'from-pink-300 to-cream-300',
  },
  {
    icon: '🏆',
    title: 'Pack milestones',
    body:
      'Crossing 25 / 50 / 75 / 100% in a pack drops a coin reward into your wallet — a "you made progress" beat between rare drops.',
    accent: 'from-cream-300 to-toxic-lime',
  },
  {
    icon: '🛡️',
    title: 'Anti-spam, kid-tested',
    body:
      'Hammering the same squishy still pops and crunches — but the economy quietly throttles. Varied play feels normal; pure spam loses value.',
    accent: 'from-jelly-300 to-lavender-300',
  },
  {
    icon: '✨',
    title: 'Reward toasts',
    body:
      'Every duplicate burst and milestone now fires a floating "+N coins" callout. Progress feels visible instead of silently ticking up.',
    accent: 'from-lavender-300 to-pink-300',
  },
]

export function WhatsNew() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="whats-new" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="What's new in 0.1.1"
          title="Tuned with real kids."
          body="The first build flew across our 6/8/8-year-old testers a little too fast. We rebalanced — without making the game stressful — so the collection lasts."
        />
        <div className="mt-12 grid sm:grid-cols-2 gap-5">
          {HIGHLIGHTS.map((h, i) => (
            <div
              key={h.title}
              className="glass-card p-6 flex gap-5 items-start"
              style={{ animationDelay: `${i * 0.05}s` }}
            >
              <div
                className={`w-12 h-12 shrink-0 rounded-2xl bg-gradient-to-br ${h.accent} flex items-center justify-center text-2xl shadow-lg`}
                aria-hidden="true"
              >
                {h.icon}
              </div>
              <div>
                <h3 className="font-display text-xl font-bold mb-2">
                  {h.title}
                </h3>
                <p className="text-white/80 leading-relaxed">{h.body}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
