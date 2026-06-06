export const meta = {
  name: 'sprite-restyle-judge',
  description: 'Pick the best reference-locked candidate per squishy and gate on card-consistency',
  phases: [{ title: 'Judge', detail: 'one vision agent per sprite scores candidates vs the card' }],
}

const NAMES = [
  "Soft Dumpling", "Jelly Bun", "Peach Mochi", "Syrup Cube", "Cream Puff",
  "Rice Ball Squish", "Marshmallow Puff", "Pudding Pop", "Strawberry Dumpling",
  "Rainbow Jelly Bun", "Sparkle Mochi", "Golden Syrup Cube", "Galaxy Dumpling",
  "Crystal Mochi", "Neon Dessert Blob", "Celestial Dumpling Core",
  "Goo Ball", "Bubble Blob", "Stretch Cube", "Soft Stress Orb", "Jelly Pad",
  "Sticky Pop Ball", "Wobble Drop", "Squish Capsule", "Glitter Goo Ball",
  "Shockwave Blob", "Frost Gel Cube", "Prism Stress Orb", "Plasma Goo Ball",
  "Aurora Stretch Cube", "Cosmic Jelly Pad", "Singularity Goo Core",
  "Blushy Bun Bunny", "Squish Bat", "Puff Ghost", "Wobble Kitty",
  "Tiny Blob Monster", "Soft Fang Critter", "Sleepy Slime Pet",
  "Round Eared Creature", "Star Eyed Bunny", "Moon Bat Blob", "Glow Ghost Puff",
  "Candy Fang Creature", "Dream Eater Squish", "Arcane Wobble Kitty",
  "Phantom Jelly Beast", "Mythic Plush Familiar",
]

const CARDS_DIR = 'D:\\squishy-smash\\assets\\cards\\final_48'
const PROTO = 'D:\\squishy-smash\\_sprite_restyle_proto\\candidates'
const pad3 = n => String(n).padStart(3, '0')
const packOrder = { 'Goo & Fidgets': 0, 'Creepy-Cute Creatures': 1, 'Squishy Foods': 2 }

const cards = NAMES.map((name, i) => {
  const n = i + 1
  const num = pad3(n)
  const under = name.replace(/ /g, '_')
  const slug = name.toLowerCase().replace(/ /g, '_')
  const pack = n <= 16 ? 'Squishy Foods' : (n <= 32 ? 'Goo & Fidgets' : 'Creepy-Cute Creatures')
  return {
    n, num, name, slug, pack,
    card: `${CARDS_DIR}\\${num}_${under}.webp`,
    cands: [0, 1, 2].map(j => `${PROTO}\\${slug}\\cand_${j}.png`),
  }
}).sort((a, b) => (packOrder[a.pack] - packOrder[b.pack]) || (a.n - b.n))

const SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['best_index', 'best_recognizability', 'gameplay_fit', 'verdict', 'rationale', 'candidates'],
  properties: {
    best_index: { type: 'integer', minimum: 0, description: 'index (cand_N) of the winning candidate' },
    best_recognizability: { type: 'integer', minimum: 1, maximum: 5, description: 'does the winner read as the SAME character as the card (5=yes obviously, 1=different creature)' },
    gameplay_fit: { type: 'integer', minimum: 1, maximum: 5, description: 'clean single centered character, reads at ~144px, cutout-able, no card chrome' },
    verdict: { type: 'string', enum: ['pass', 'reroll'] },
    rationale: { type: 'string' },
    candidates: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['index', 'recognizability', 'note'],
        properties: {
          index: { type: 'integer' },
          recognizability: { type: 'integer', minimum: 1, maximum: 5 },
          note: { type: 'string' },
        },
      },
    },
  },
}

const results = await parallel(cards.map(c => () => {
  const list = c.cands.map((p, i) => `  index ${i}: ${p}`).join('\n')
  return agent(
    `You are the QA judge for "Squishy Smash", a kids' collect-and-smash game. ` +
    `The player collects a glossy trading CARD of a character, then smashes a gameplay SPRITE of that same character — they must look like the SAME creature.\n\n` +
    `Compare candidate gameplay sprites against the canonical card art and pick the best.\n` +
    `CARD (canon — judge the central hero character only, ignore frame/text/background): ${c.card}\n` +
    `CANDIDATES (open every one with Read):\n${list}\n\n` +
    `Character: "${c.name}" (${c.pack}).\n\n` +
    `For EACH candidate, score recognizability 1-5 (5 = obviously the same character as the card: matching color, body shape, signature features, face/expression; 1 = reads as a different creature). ` +
    `Also weigh gameplay-fitness: a single centered character, clean alpha-cutout-able on white, not so busy it turns to mush at ~144px, no card frame/text/extra characters.\n\n` +
    `Choose best_index (the cand_N index of the winner). Set best_recognizability and gameplay_fit for that winner. ` +
    `Gate: verdict 'pass' if the winner is recognizably the same character (best_recognizability >= 3 AND gameplay_fit >= 3); otherwise 'reroll'. ` +
    `Give a concise rationale and a one-line note per candidate. Be honest and critical.`,
    { label: `judge:${c.num} ${c.name}`, phase: 'Judge', schema: SCHEMA }
  ).then(r => r
    ? { slug: c.slug, name: c.name, pack: c.pack, ...r }
    : { slug: c.slug, name: c.name, pack: c.pack, best_index: 0, best_recognizability: 0, gameplay_fit: 0, verdict: 'reroll', rationale: 'judge agent returned null', candidates: [] }
  )
}))

const pass = results.filter(r => r.verdict === 'pass')
const reroll = results.filter(r => r.verdict !== 'pass')
const avgRec = pass.length ? Math.round((pass.reduce((s, r) => s + r.best_recognizability, 0) / pass.length) * 100) / 100 : 0
log(`Judged ${results.length}: ${pass.length} pass, ${reroll.length} reroll. Avg winner recognizability (passes): ${avgRec}/5.`)

return {
  results,
  chosen: Object.fromEntries(results.map(r => [r.slug, r.best_index])),
  summary: {
    total: results.length,
    pass: pass.length,
    reroll: reroll.length,
    reroll_slugs: reroll.map(r => ({ slug: r.slug, name: r.name, rec: r.best_recognizability, why: r.rationale })),
  },
}
