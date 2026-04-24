import { useState } from 'react'
import { useReveal } from '../hooks/useReveal'

export function JoinCTA() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  const [email, setEmail] = useState('')
  const [submitted, setSubmitted] = useState(false)

  function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!email.includes('@')) return
    // Netlify Forms — the action attribute is wired via data-netlify
    // on the form below so this client submit is only for optimistic
    // UI. The real POST happens on the synthetic Netlify-handler.
    setSubmitted(true)
  }

  return (
    <section id="join" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-3xl mx-auto text-center reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <div className="glass-dark p-10 md:p-14 relative overflow-hidden animate-pulse-glow">
          <div
            className="absolute -top-20 -right-20 w-72 h-72 rounded-full opacity-30 blur-3xl"
            style={{ background: 'radial-gradient(circle, #FFD36E, transparent 70%)' }}
            aria-hidden="true"
          />
          <div
            className="absolute -bottom-20 -left-20 w-72 h-72 rounded-full opacity-30 blur-3xl"
            style={{ background: 'radial-gradient(circle, #C98BFF, transparent 70%)' }}
            aria-hidden="true"
          />

          <div className="relative">
            <div className="inline-block font-display text-xs font-bold uppercase tracking-[0.25em] text-cream-300 bg-white/10 px-3 py-1.5 rounded-full mb-6">
              TestFlight preview
            </div>
            <h2 className="font-display text-4xl md:text-5xl font-bold mb-4">
              Be first to squish.
            </h2>
            <p className="text-lg text-white/80 max-w-lg mx-auto mb-8">
              Drop your email and we'll send a TestFlight invite as soon as
              the next build is live. One email per release — no spam, no
              tracking, no sharing with anyone.
            </p>

            {submitted ? (
              <div className="glass-card max-w-md mx-auto p-5 animate-pop">
                <div className="text-4xl mb-2" aria-hidden="true">🎉</div>
                <p className="font-display text-lg font-bold">
                  You're in. Check your inbox for the invite.
                </p>
              </div>
            ) : (
              <form
                name="testflight"
                method="POST"
                data-netlify="true"
                onSubmit={onSubmit}
                className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto"
              >
                <input type="hidden" name="form-name" value="testflight" />
                <input
                  type="email"
                  name="email"
                  required
                  placeholder="you@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="flex-1 px-5 py-3 rounded-full bg-white/15 border border-white/25 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-cream-300 focus:border-transparent transition"
                />
                <button type="submit" className="glow-btn">
                  Notify me
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
