/* Floating bubble particle layer — sits behind everything.
 * 16 bubbles with staggered timing so the parallax never sync-loops
 * in a way the eye can pick up. */
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
    </div>
  )
}
