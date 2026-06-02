/* Floating bubble particle layer + ambient character decorations.
 *
 * 16 bubbles rise from bottom, with staggered timing so the parallax never
 * sync-loops in a way the eye can pick up. Layered ON TOP of bubbles: a
 * handful of low-opacity character silhouettes drifting gently at the page
 * edges to give the brand background a sense of living world. Characters
 * never sit in the central content column.
 */

const AMBIENT_CHARACTERS = [
  // Top-left corner, small + faded
  { img: '/website_hero/hero_011_sparkle_mochi.png',
    size: 120, top: '6%',  left: '2%',
    opacity: 0.32, anim: 'animate-float-slower' },
  // Top-right corner, mid-size
  { img: '/website_hero/hero_026_shockwave_blob.png',
    size: 140, top: '12%', right: '3%',
    opacity: 0.28, anim: 'animate-float-slow' },
  // Middle-right
  { img: '/website_hero/hero_042_moon_bat_blob.png',
    size: 110, top: '46%', right: '1.5%',
    opacity: 0.30, anim: 'animate-float-delayed' },
  // Middle-left, lower
  { img: '/website_hero/hero_014_crystal_mochi.png',
    size: 130, top: '58%', left: '2%',
    opacity: 0.30, anim: 'animate-float' },
  // Bottom-left
  { img: '/website_hero/hero_045_dream_eater_squish.png',
    size: 100, top: '78%', left: '4%',
    opacity: 0.28, anim: 'animate-float-slow' },
  // Bottom-right
  { img: '/website_hero/hero_029_plasma_goo_ball.png',
    size: 120, top: '82%', right: '3%',
    opacity: 0.30, anim: 'animate-float-slower' },
]

export function Bubbles() {
  const bubbles = [
    { size: 42, left: '4%',  delay: '0s',   duration: '8s' },
    { size: 28, left: '12%', delay: '2.2s', duration: '10s' },
    { size: 64, left: '22%', delay: '4.1s', duration: '12s' },
    { size: 34, left: '33%', delay: '1.0s', duration: '9s' },
    { size: 52, left: '48%', delay: '3.0s', duration: '11s' },
    { size: 22, left: '58%', delay: '5.5s', duration: '7s' },
    { size: 48, left: '70%', delay: '0.4s', duration: '10s' },
    { size: 36, left: '80%', delay: '3.8s', duration: '8s' },
    { size: 58, left: '92%', delay: '1.5s', duration: '13s' },
    { size: 24, left: '45%', delay: '6.2s', duration: '9s' },
    { size: 40, left: '7%',  delay: '7.5s', duration: '11s' },
    { size: 30, left: '66%', delay: '4.9s', duration: '8s' },
    { size: 46, left: '18%', delay: '9.1s', duration: '12s' },
    { size: 20, left: '87%', delay: '2.7s', duration: '7s' },
    { size: 56, left: '52%', delay: '8.2s', duration: '14s' },
    { size: 26, left: '38%', delay: '11s',  duration: '9s' },
  ]
  return (
    <div
      className="fixed inset-0 pointer-events-none z-0 overflow-hidden"
      aria-hidden="true"
    >
      {bubbles.map((b, i) => (
        <span
          key={i}
          className="bubble"
          style={{
            width: b.size,
            height: b.size,
            left: b.left,
            bottom: '-10%',
            animation: `bubbleRise ${b.duration} ease-in ${b.delay} infinite`,
          }}
        />
      ))}
      {/* Ambient character decorations — hidden on small screens to avoid
          competing with content; kept off the central reading column on
          large screens. */}
      <div className="hidden lg:block absolute inset-0">
        {AMBIENT_CHARACTERS.map((c, i) => (
          <img
            key={i}
            src={c.img}
            alt=""
            aria-hidden="true"
            className={`absolute ${c.anim}`}
            style={{
              top: c.top,
              left: c.left,
              right: c.right,
              width: c.size,
              height: c.size,
              opacity: c.opacity,
              filter: 'drop-shadow(0 12px 24px rgba(0, 0, 0, 0.35))',
            }}
          />
        ))}
      </div>
    </div>
  )
}
