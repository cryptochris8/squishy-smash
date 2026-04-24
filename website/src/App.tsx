import { Bubbles } from './components/Bubbles'
import { Collection } from './components/Collection'
import { CoreLoop } from './components/CoreLoop'
import { Footer } from './components/Footer'
import { ForParents } from './components/ForParents'
import { Hero } from './components/Hero'
import { JoinCTA } from './components/JoinCTA'
import { Nav } from './components/Nav'
import { Packs } from './components/Packs'

function App() {
  return (
    <div className="relative">
      <Bubbles />
      <Nav />
      <Hero />
      <CoreLoop />
      <Collection />
      <Packs />
      <ForParents />
      <JoinCTA />
      <Footer />
    </div>
  )
}

export default App
