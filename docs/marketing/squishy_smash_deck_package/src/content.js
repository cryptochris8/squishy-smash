/**
 * Squishy Smash — Licensing & Manufacturing Deck
 * Single source of truth for all slide copy.
 *
 * Consumed by BOTH src/deck.js (PPTX) and src/build_html.js (PDF) so the two
 * exports can never drift apart.
 *
 * ACCURACY RULES ENFORCED HERE (see docs/05_CLAUDE_CODE_BUILD_INSTRUCTIONS.md):
 *  - No sales, download, audience-size, retail-partner, patent or trademark claims.
 *  - Anything not launched is worded "proposed", "planned", "potential" or "target".
 *  - The 3D models are described as an existing starting point, never mold-ready.
 *  - No cost or lead-time figures are presented as quotes.
 */

// Things that are externally checkable today. Anything not on this list does
// not get stated as fact anywhere in the deck.
const VERIFIED = {
  characterCount: 48,
  rarityBreakdown: '24 Common · 12 Rare · 9 Epic · 3 Legendary',
  packs: ['Squishy Foods', 'Goo & Fidgets', 'Creepy Cute'],
  modelCount: 6,
  appStoreUrl: 'apps.apple.com/us/app/squishy-smash/id6762549537',
  robloxPlace: '105594294243426',
  website: 'squishysmash.com',
  book1: 'Squishy Smash: Meet the Squishies',
  book2: 'Squishy Smash: The Lost Sparkle',
  author: 'Christopher Ryan Campbell',
  year: 2026,
};

const CONTACT = {
  name: 'Christopher Ryan Campbell',
  company: 'Athlete Domains, LLC',
  email: 'support@squishysmash.com',
  website: 'www.squishysmash.com',
  phone: '864-606-2284',
};

const PILOT = [
  { slug: 'soft_dumpling', name: 'Soft Dumpling', num: '001/048', rarity: 'Common', pack: 'Squishy Foods' },
  { slug: 'goo_ball', name: 'Goo Ball', num: '017/048', rarity: 'Common', pack: 'Goo & Fidgets' },
  { slug: 'blushy_bun_bunny', name: 'Blushy Bun Bunny', num: '033/048', rarity: 'Common', pack: 'Creepy Cute' },
  { slug: 'celestial_dumpling_core', name: 'Celestial Dumpling Core', num: '016/048', rarity: 'Legendary', pack: 'Squishy Foods' },
  { slug: 'singularity_goo_core', name: 'Singularity Goo Core', num: '032/048', rarity: 'Legendary', pack: 'Goo & Fidgets' },
  { slug: 'mythic_plush_familiar', name: 'Mythic Plush Familiar', num: '048/048', rarity: 'Legendary', pack: 'Creepy Cute' },
];

const SLIDES = [
  {
    id: 'cover',
    layout: 'cover',
    title: 'Squishy Smash',
    subtitle: 'Licensing & Manufacturing Opportunity',
    support: 'An original character universe ready to become a physical collectible toy line.',
    models: ['blushy_bun_bunny', 'soft_dumpling', 'goo_ball', 'celestial_dumpling_core', 'mythic_plush_familiar'],
  },

  {
    id: 'opportunity',
    layout: 'statement',
    kicker: 'The Opportunity',
    title: 'From Digital Characters to Real-World Collectibles',
    body: [
      'Squishy Smash is a developed children’s character brand with original art, two published books, trading cards, a mobile game, a Roblox experience, and 3D character models already in place.',
      'The next step is bringing selected characters into the physical world as collectible slow-rise squishy toys.',
    ],
    callout: 'The brand foundation is built. Product development can begin from existing character assets.',
    art: 'model_soft_dumpling',
  },

  {
    id: 'ecosystem',
    layout: 'hub',
    kicker: 'Brand Ecosystem',
    title: 'A Connected Character Universe',
    hub: 'SQUISHY\nSMASH',
    spokes: [
      { label: 'Storybook', note: 'The Lost Sparkle' },
      { label: 'Character Book', note: 'Meet the Squishies' },
      { label: 'Trading Cards', note: '48 collectible cards' },
      { label: 'iOS App', note: 'Live on the App Store' },
      { label: 'Roblox Game', note: 'Live experience' },
      { label: '3D Models', note: '6 characters modelled' },
      { label: 'Physical Toys', note: 'Proposed next step', proposed: true },
    ],
    body: 'Every part of the brand reinforces the others. Physical squishies can connect directly to the books, games, and cards.',
  },

  {
    id: 'ip',
    layout: 'grid48',
    kicker: 'Existing Intellectual Property',
    title: '48 Original Characters',
    body: 'Squishy Smash includes 48 original characters with distinct names, personalities, artwork, and collectible rarity tiers.',
    points: [
      'Original character names and artwork',
      'Consistent visual identity across every surface',
      'Existing 2D artwork for all 48 characters',
      'Three themed packs, designed for expansion',
    ],
    caption: `All 48 characters shown · ${VERIFIED.rarityBreakdown}`,
  },

  {
    id: 'manufacturing',
    layout: 'process',
    kicker: 'Manufacturing Readiness',
    title: 'Built for a Faster Path to Prototype',
    body: 'Six characters already have 3D models generated from their original card art. These are a starting point for design-for-manufacturing review — not finished tooling geometry.',
    steps: ['Existing 3D Model', 'Manufacturing Review', 'Mold-Ready Geometry', 'Prototype', 'Production Sample'],
    points: [
      'GLB models available; OBJ, FBX or STL can be supplied',
      'High-resolution colour references for all 48 characters',
      'Front, side and back views can be rendered on request',
      'Design-for-manufacturing adjustments are expected and welcomed',
    ],
    models: ['soft_dumpling', 'goo_ball', 'blushy_bun_bunny'],
    disclaimer: 'Existing models are concept geometry. Mold-ready files would be produced with the manufacturer.',
  },

  {
    id: 'product',
    layout: 'spec',
    kicker: 'Proposed Product',
    title: 'Collectible Slow-Rise Squishy Characters',
    specs: [
      { label: 'Construction', value: 'Soft polyurethane foam' },
      { label: 'Response', value: 'Slow-rise squeeze' },
      { label: 'Size', value: 'Approx. 4–6 inches tall' },
      { label: 'Finish', value: 'Durable painted coating' },
      { label: 'Options', value: 'Scent, glitter, glow or colour-change' },
      { label: 'Packaging', value: 'Window box, polybag or blind box' },
    ],
    art: 'model_blushy_bun_bunny',
    disclaimer: 'Initial target specifications for manufacturer discussion. Nothing here is final — all specifications are open to your recommendations.',
  },

  {
    id: 'pilot',
    layout: 'lineup',
    kicker: 'Pilot Collection',
    title: 'Proposed First Release',
    seriesName: 'Squishy Smash Founders Series',
    body: 'Launching with six hero characters rather than all 48. These six are proposed first because each already has an existing 3D model, and together they cover all three packs and both ends of the rarity range.',
    benefits: ['Lower tooling investment', 'Faster testing', 'Clearer customer feedback', 'Easier quality control', 'Builds anticipation for later series'],
    lineup: PILOT,
    disclaimer: 'Proposed selections. Final lineup to be confirmed with the manufacturing partner.',
  },

  {
    id: 'collectibility',
    layout: 'twocol',
    kicker: 'Collectibility',
    title: 'Designed to Encourage Repeat Discovery',
    colA: {
      heading: 'Built-in collectible structure',
      items: ['Four rarity tiers per character', 'Numbered series (001/048 – 048/048)', 'A matching collectible card for every character', 'Character profile and story for each', 'Three themed packs'],
    },
    colB: {
      heading: 'Potential finishes and variants',
      items: ['Glow-in-the-dark', 'Scented', 'Glitter and metallic', 'Colour-changing', 'Seasonal and holiday editions', 'Chase variants'],
    },
    disclaimer: 'Every character is individually named and numbered, so collections are transparent — a buyer always knows exactly what they are purchasing.',
  },

  {
    id: 'crossplatform',
    layout: 'digital',
    kicker: 'Cross-Platform Connection',
    title: 'Every Toy Can Unlock More of the World',
    body: 'The physical product can become a bridge between the books, games and cards. The digital surfaces below are live today; the toy-to-digital connections are planned features, not shipped ones.',
    live: [
      { label: 'iOS App', note: 'Live on the App Store', art: 'app_01' },
      { label: 'Roblox Experience', note: 'Live — "The Lost Sparkle"', art: 'roblox' },
      { label: 'Collection Album', note: '48-card in-app album', art: 'app_02' },
    ],
    planned: ['QR code to the brand site', 'Roblox cosmetic bonus', 'iOS app reward', 'Character profile page', 'Printable activities'],
  },

  {
    id: 'packaging',
    layout: 'packaging',
    kicker: 'Packaging Direction',
    title: 'Retail-Ready Storytelling',
    components: ['Squishy Smash logo', 'Character name', 'Series number', 'Rarity badge', 'Character artwork', 'Short personality description', 'QR code area', 'Safety and compliance panel'],
    formats: ['Window box', 'Branded polybag', 'Blind box', 'Multi-character collector set'],
    body: 'The existing trading-card design already contains every element a retail package needs — name, number, rarity, artwork and character description. It is a natural basis for packaging artwork.',
    disclaimer: 'Concept direction only. Existing trading card shown as a design reference, not as final packaging artwork.',
    art: 'card_blushy_bun_bunny',
  },

  {
    id: 'audience',
    layout: 'audience',
    kicker: 'Target Audience',
    title: 'Who Squishy Smash Is Built For',
    primary: 'Children approximately ages 4–10',
    secondary: ['Parents buying gifts', 'Collectible toy fans', 'Roblox and mobile game players', 'Book readers', 'Teachers and family gift buyers'],
    occasions: ['Birthdays', 'Holidays', 'Rewards', 'Stocking stuffers', 'Book bundles', 'Collectible play'],
    disclaimer: 'Proposed age range. The final age grade must be confirmed through product design, testing and applicable toy-safety standards.',
  },

  {
    id: 'ask',
    layout: 'ask',
    kicker: 'Partnership Request',
    title: 'What We Are Seeking',
    items: ['Prototype development', 'Design-for-manufacturing review', 'Mold and tooling estimates', 'Minimum order quantities', 'Unit pricing at multiple volumes', 'Packaging capabilities', 'Safety testing support', 'Production timelines', 'Shipping and fulfilment options'],
    callout: 'Where feasible, we would appreciate pricing at 250, 500, 1,000 and 5,000 units per design.',
  },

  {
    id: 'why',
    layout: 'why',
    kicker: 'Why Squishy Smash',
    title: 'More Than a Single Toy',
    points: [
      { h: 'Original, expandable IP', d: '48 characters across three themed packs' },
      { h: 'Published presence', d: 'Two books available on Amazon' },
      { h: 'Existing card designs', d: 'A finished collectible card for every character' },
      { h: 'Live digital surfaces', d: 'iOS app and Roblox experience' },
      { h: '3D foundation', d: 'Six characters already modelled' },
      { h: 'Room to grow', d: 'Multiple future product categories' },
    ],
    callout: 'A physical squishy line would join an ecosystem that already exists.',
  },

  {
    id: 'expansion',
    layout: 'expansion',
    kicker: 'Future Expansion',
    title: 'Long-Term Product Possibilities',
    focus: { label: 'Collectible Squishies', note: 'The immediate focus' },
    categories: ['Additional squishy series', 'Plush toys', 'Mini figures', 'Keychains', 'Backpacks & accessories', 'Activity kits', 'Stickers', 'Apparel', 'Classroom & party products'],
    disclaimer: 'Concept categories illustrating licensing breadth. No timeline is proposed for these.',
  },

  {
    id: 'contact',
    layout: 'contact',
    title: 'Let’s Bring Squishy Smash to Life',
    body: 'We are seeking experienced manufacturing and licensing partners to help develop the first physical Squishy Smash collection.',
    contact: CONTACT,
    art: 'model_mythic_plush_familiar',
  },

  {
    id: 'appendix-gallery',
    layout: 'appendixGallery',
    kicker: 'Appendix A',
    title: 'Full Character Gallery',
    body: `All ${VERIFIED.characterCount} characters. Every character has finished artwork, a name, a series number and a rarity tier.`,
    caption: VERIFIED.rarityBreakdown,
  },

  {
    id: 'appendix-rfq',
    layout: 'appendixRfq',
    kicker: 'Appendix B',
    title: 'Manufacturer RFQ',
    intro: 'Custom slow-rise polyurethane foam squishy based on an original Squishy Smash character.',
    inputsWeProvide: ['Existing 3D model (GLB)', 'Colour character artwork', 'Front / side / back references', 'Logo and branding assets', 'Packaging concept'],
    questions: [
      'Prototype and sample cost',
      'Mold and tooling cost per character',
      'Minimum order quantity',
      'Unit cost at 250 / 500 / 1,000 / 5,000 pieces',
      'Development and production timelines',
      'Available foam densities and rebound speeds',
      'Paint and coating options',
      'Scent, glitter, glow or colour-change options',
      'Packaging capabilities',
      'Product safety testing support',
      'Shipping terms and freight options',
      'Ownership and storage of molds',
      'Sample revision policy',
      'Payment schedule',
    ],
    safety: 'Please confirm whether you can support applicable U.S. toy-safety requirements, including age grading, labelling, tracking information and third-party testing where required.',
    disclaimer: 'This list is a discussion starting point, not legal advice. Compliance requirements will be confirmed with qualified professionals and accredited testing laboratories.',
  },
];

module.exports = { SLIDES, PILOT, CONTACT, VERIFIED };
