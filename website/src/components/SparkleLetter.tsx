import { useState } from 'react'

// The Squishy Sparkle Letter — a PARENT-facing email signup and the flywheel's
// owned-audience engine (turns rented algorithm reach into a list we control).
//
// COPPA by design: the copy only ever addresses a grown-up, and the site never
// collects anything from a child. Backed by Netlify Forms — the hidden
// detection form lives in index.html so the build registers "sparkle-letter";
// this component posts to it over AJAX (allowed by the site CSP's connect-src
// 'self') so the page never leaves the app. Progressive enhancement: without
// JS the form still submits natively to Netlify.
export function SparkleLetter() {
  const [status, setStatus] = useState<'idle' | 'sending' | 'done' | 'error'>(
    'idle',
  )

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    if (status === 'sending') return
    const data = new FormData(e.currentTarget)
    // Honeypot: a filled hidden field means a bot — quietly show success.
    if (((data.get('bot-field') as string) || '').length > 0) {
      setStatus('done')
      return
    }
    setStatus('sending')
    try {
      const body = new URLSearchParams()
      data.forEach((value, key) => body.append(key, value as string))
      const res = await fetch('/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
      })
      setStatus(res.ok ? 'done' : 'error')
    } catch {
      setStatus('error')
    }
  }

  if (status === 'done') {
    return (
      <div className="glass-dark p-8 text-center">
        <p className="font-display text-2xl font-bold text-cream-300">
          You&rsquo;re on the list! ✨
        </p>
        <p className="text-white/80 mt-2">
          Watch your inbox for this month&rsquo;s Magic Word to share with your
          kids.
        </p>
      </div>
    )
  }

  return (
    <form
      name="sparkle-letter"
      method="POST"
      action="/"
      data-netlify="true"
      onSubmit={onSubmit}
      className="glass-dark p-8 text-center"
    >
      <input type="hidden" name="form-name" value="sparkle-letter" />
      {/* Honeypot — hidden from real users, catnip for bots. */}
      <p className="hidden" aria-hidden="true">
        <label>
          Leave this empty: <input name="bot-field" tabIndex={-1} />
        </label>
      </p>

      <div className="inline-block font-display text-xs font-bold uppercase tracking-[0.25em] text-cream-300 bg-white/10 px-3 py-1.5 rounded-full mb-4">
        For grown-ups
      </div>
      <h3 className="font-display text-2xl md:text-3xl font-bold mb-2">
        The Squishy Sparkle Letter
      </h3>
      <p className="text-white/80 max-w-md mx-auto mb-6">
        A gentle once-a-month note for parents — a new in-game{' '}
        <strong className="text-white">Magic Word</strong> to share with your
        kids, plus what&rsquo;s new across the game, app, and books. No spam,
        ever.
      </p>

      <div className="flex flex-col sm:flex-row gap-3 items-stretch justify-center max-w-lg mx-auto">
        <label htmlFor="sl-email" className="sr-only">
          Your email address
        </label>
        <input
          id="sl-email"
          type="email"
          name="email"
          required
          autoComplete="email"
          placeholder="grown-up@email.com"
          className="w-full sm:flex-1 rounded-full px-5 py-3 bg-white text-bg-deep font-semibold placeholder:text-bg-deep/40 focus:outline-none focus:ring-4 focus:ring-pink-300/50"
        />
        <button
          type="submit"
          disabled={status === 'sending'}
          className="glow-btn whitespace-nowrap disabled:opacity-60"
        >
          {status === 'sending' ? 'Sending…' : 'Get the Sparkle Letter'}
        </button>
      </div>

      {status === 'error' && (
        <p className="text-pink-300 mt-4 text-sm" role="alert">
          Hmm, that didn&rsquo;t send. Please try again in a moment.
        </p>
      )}
      <p className="text-white/50 text-xs mt-5">
        We only ever ask a grown-up. One-tap unsubscribe anytime.
      </p>
    </form>
  )
}
