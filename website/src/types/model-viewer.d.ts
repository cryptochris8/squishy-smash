// JSX typing for the <model-viewer> custom element (@google/model-viewer).
// Only the attributes the site actually uses are declared.
import type * as React from 'react'

declare module 'react' {
  namespace JSX {
    interface IntrinsicElements {
      'model-viewer': React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement>,
        HTMLElement
      > & {
        src?: string
        poster?: string
        alt?: string
        loading?: 'auto' | 'lazy' | 'eager'
        reveal?: 'auto' | 'interaction' | 'manual'
        'camera-controls'?: boolean
        'auto-rotate'?: boolean
        'auto-rotate-delay'?: number | string
        'rotation-per-second'?: string
        'shadow-intensity'?: number | string
        'shadow-softness'?: number | string
        'camera-orbit'?: string
        'min-camera-orbit'?: string
        'max-camera-orbit'?: string
        'field-of-view'?: string
        'interaction-prompt'?: 'auto' | 'none'
        'touch-action'?: string
        'disable-zoom'?: boolean
        exposure?: number | string
      }
    }
  }
}
