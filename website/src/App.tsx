import { Bubbles } from './components/Bubbles'
import { Collection } from './components/Collection'
import { CoreLoop } from './components/CoreLoop'
import { Footer } from './components/Footer'
import { ForParents } from './components/ForParents'
import { Hero } from './components/Hero'
import { JoinCTA } from './components/JoinCTA'
import { Nav } from './components/Nav'
import { Packs } from './components/Packs'
import { WhatsNew } from './components/WhatsNew'

function App() {
  return (
    <div className="relative">
      <Bubbles />
      {/* Visually-hidden skip link for keyboard / screen-reader users
          so the main content is one tab away from the top of the page,
          regardless of how long the nav grows. Becomes visible on
          keyboard focus. */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-[100] focus:px-4 focus:py-2 focus:rounded-full focus:bg-white focus:text-bg-deep focus:font-bold focus:shadow-lg"
      >
        Skip to content
      </a>
      <Nav />
      <main id="main-content">
        <Hero />
        <CoreLoop />
        <WhatsNew />
        <Collection />
        <Packs />
        <ForParents />
        <JoinCTA />
      </main>
      <Footer />
    </div>
  )
}

export default App
