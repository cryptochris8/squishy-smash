import { useEffect, useRef, useState } from 'react'

/**
 * Drop-in scroll-reveal hook. Returns a ref + a boolean — attach the
 * ref to the element you want to animate and toggle the class based
 * on the boolean. Uses IntersectionObserver so content flows in as
 * the user scrolls rather than all at once on load.
 */
export function useReveal<T extends HTMLElement>(options?: IntersectionObserverInit) {
  const ref = useRef<T | null>(null)
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    const node = ref.current
    if (!node) return
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setIsVisible(true)
            observer.unobserve(entry.target)
          }
        }
      },
      { threshold: 0.15, ...options },
    )
    observer.observe(node)
    return () => observer.disconnect()
  }, [options])

  return { ref, isVisible }
}
