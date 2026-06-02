import { useReveal } from '../hooks/useReveal'
import { SectionHeading } from './CoreLoop'
import {
  AMAZON_BOOK_URL,
  AMAZON_BOOK2_URL,
  BOOK2_READALONG_YOUTUBE_ID,
} from '../constants/links'

export function Books() {
  const { ref, isVisible } = useReveal<HTMLDivElement>()
  return (
    <section id="books" className="relative z-10 py-24 px-6">
      <div
        ref={ref}
        className={`max-w-6xl mx-auto reveal-on-scroll ${isVisible ? 'is-visible' : ''}`}
      >
        <SectionHeading
          kicker="The story so far"
          title="Squishy Smash: The Lost Sparkle"
          body="Book Two in the Squishy Smash series. A read-aloud bedtime picture book for ages 4–8 — about three friends who leave home for the first time and find each other."
        />

        {/* Trio cross-promo hero banner — the three Book 2 protagonists,
            same 3D card style, in the dusk-warm palette echoing the book
            cover. */}
        <div
          className="mt-10 relative w-full rounded-3xl overflow-hidden"
          style={{
            aspectRatio: '16 / 9',
            boxShadow: '0 32px 64px -24px rgba(228, 165, 108, 0.4)',
            border: '1px solid rgba(245, 233, 208, 0.2)',
          }}
        >
          <img
            src="/website_hero/trio_book2_protagonists.png"
            alt="Soft Dumpling, Goo Ball, and Blushy Bun Bunny meet at a dusk-warm horizon under the lost Sparkle"
            loading="lazy"
            className="absolute inset-0 w-full h-full object-cover"
          />
        </div>

        <div className="mt-10 grid lg:grid-cols-[1.4fr_1fr] gap-8 items-center">
          {/* Responsive 16:9 YouTube embed */}
          <div className="glass-card overflow-hidden p-0">
            <div className="relative w-full" style={{ aspectRatio: '16 / 9' }}>
              <iframe
                src={`https://www.youtube.com/embed/${BOOK2_READALONG_YOUTUBE_ID}?rel=0`}
                title="Squishy Smash: The Lost Sparkle — Read Aloud"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowFullScreen
                loading="lazy"
                className="absolute inset-0 w-full h-full"
              />
            </div>
          </div>

          <div className="flex flex-col gap-5">
            <p className="text-white/85 leading-relaxed">
              When the Sparkle that lights three small worlds flickers and splits into three shards, Soft Dumpling, Goo Ball, and Blushy Bun Bunny leave home for the first time to find the pieces. What they find on the way is each other.
            </p>
            <p className="text-white/70 leading-relaxed text-sm">
              A gentle bedtime story about brave kindness, friendship across difference, and the light that comes from being found.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 mt-2">
              <a
                href={AMAZON_BOOK2_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="glow-btn text-sm inline-flex items-center justify-center gap-2"
              >
                Get Book Two on Amazon
              </a>
              <a
                href={`https://youtu.be/${BOOK2_READALONG_YOUTUBE_ID}`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-full border border-white/25 bg-white/5 hover:bg-white/10 text-sm font-display font-semibold transition-colors"
              >
                Watch on YouTube
              </a>
            </div>
            <a
              href={AMAZON_BOOK_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-white/55 hover:text-cream-300 transition-colors inline-flex items-center gap-1"
            >
              <span>Also available: Book One — <em>Meet the Squishies</em></span>
              <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
