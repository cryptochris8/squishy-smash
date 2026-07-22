import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Books } from './components/Books'
import { Bubbles } from './components/Bubbles'
import { Collection } from './components/Collection'
import { CoreLoop } from './components/CoreLoop'
import { FeaturedEpics } from './components/FeaturedEpics'
import { FeaturedLegendaries } from './components/FeaturedLegendaries'
import { Footer } from './components/Footer'
import { ForParents } from './components/ForParents'
import { Hero } from './components/Hero'
import { Hub } from './components/Hub'
import { JoinCTA } from './components/JoinCTA'
import { Nav } from './components/Nav'
import { PackPage } from './components/PackPage'
import { Packs } from './components/Packs'
import { RobloxSection } from './components/RobloxSection'
import { SparkleLetter } from './components/SparkleLetter'
import { SpinSquishy } from './components/SpinSquishy'
import { WhatsNew } from './components/WhatsNew'

function HomePage() {
  return (
    <>
      <Hero />
      <CoreLoop />
      <WhatsNew />
      <RobloxSection />
      <FeaturedLegendaries />
      <FeaturedEpics />
      <SpinSquishy />
      <Books />
      <Collection />
      <Packs />
      <ForParents />
      <section id="sparkle-letter" className="relative z-10 py-16 px-6">
        <div className="max-w-2xl mx-auto">
          <SparkleLetter />
        </div>
      </section>
      <JoinCTA />
    </>
  )
}

function App() {
  return (
    <BrowserRouter>
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
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/hub" element={<Hub />} />
            <Route path="/packs/:slug" element={<PackPage />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </BrowserRouter>
  )
}

export default App
