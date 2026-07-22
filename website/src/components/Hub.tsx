import {
  APP_STORE_URL,
  ROBLOX_GAME_URL,
  AMAZON_BOOK2_URL,
  BOOK2_READALONG_YOUTUBE_ID,
} from '../constants/links'
import { SparkleLetter } from './SparkleLetter'

const READALONG_URL = `https://www.youtube.com/watch?v=${BOOK2_READALONG_YOUTUBE_ID}`

// The link-in-bio hub — the single focused destination for social bios
// (@squishy_smash on TikTok / Reels / Shorts). Cold traffic converts better on
// a short, one-decision page than on the full marketing site, so this is
// deliberately spare: the four doors into the world, the trust promise, and the
// parent Sparkle Letter. Reachable at squishysmash.com/hub.
export function Hub() {
  return (
    <section className="relative z-10 px-6 pt-16 pb-24">
      <div className="max-w-lg mx-auto text-center">
        <h1 className="font-display text-4xl md:text-5xl font-bold">
          Squishy Smash
        </h1>
        <p className="font-display text-sm font-bold uppercase tracking-[0.22em] text-cream-300 mt-3">
          3 lands · 56 friends · 1 dad · 0 loot boxes
        </p>
        <p className="text-white/80 mt-4">
          A wholesome squishy world a dad built for his three daughters — squish
          sleepy friends till they Happy&nbsp;Pop, then collect every one. Free
          to start.
        </p>

        <div className="flex flex-col gap-3 mt-8">
          <HubLink
            href={ROBLOX_GAME_URL}
            primary
            icon={<RobloxIcon />}
            label="Play free on Roblox"
            sub="The full three-land adventure"
          />
          <HubLink
            href={APP_STORE_URL}
            icon={<AppleLogo />}
            label="Get the app"
            sub="Your collection, in your pocket"
          />
          <HubLink
            href={AMAZON_BOOK2_URL}
            icon={<BookIcon />}
            label="Read the story"
            sub="The Lost Sparkle picture book"
          />
          <HubLink
            href={READALONG_URL}
            icon={<SpeakerIcon />}
            label="Free read-along"
            sub="The whole story, read aloud"
          />
        </div>

        <div className="inline-flex items-center gap-2 mt-8 font-display text-xs font-bold uppercase tracking-[0.15em] text-cream-300 bg-white/10 px-4 py-2 rounded-full">
          ✨ Free capsules forever · No loot boxes
        </div>

        <div className="mt-10 text-left">
          <SparkleLetter />
        </div>
      </div>
    </section>
  )
}

function HubLink({
  href,
  label,
  sub,
  icon,
  primary,
}: {
  href: string
  label: string
  sub: string
  icon: React.ReactNode
  primary?: boolean
}) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className={`group flex items-center gap-4 w-full rounded-2xl px-5 py-4 text-left transition-transform hover:scale-[1.02] focus:outline-none focus:ring-4 focus:ring-pink-300/50 ${
        primary
          ? 'bg-gradient-to-r from-pink-400 to-pink-500 text-white shadow-lg shadow-pink-500/30'
          : 'glass-dark hover:bg-white/10'
      }`}
    >
      <span
        className={`flex-none grid place-items-center w-11 h-11 rounded-xl ${
          primary ? 'bg-white/20' : 'bg-white/10'
        }`}
        aria-hidden="true"
      >
        {icon}
      </span>
      <span className="flex-1">
        <span className="block font-display font-bold text-lg leading-tight">
          {label}
        </span>
        <span
          className={`block text-sm ${primary ? 'text-white/80' : 'text-white/60'}`}
        >
          {sub}
        </span>
      </span>
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="w-5 h-5 flex-none opacity-50 group-hover:opacity-100 group-hover:translate-x-0.5 transition"
        aria-hidden="true"
      >
        <path d="M9 6l6 6-6 6" />
      </svg>
    </a>
  )
}

function RobloxIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M21 6H3c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zM11 13H8v3H6v-3H3v-2h3V8h2v3h3v2zm4.5 2a1.5 1.5 0 110-3 1.5 1.5 0 010 3zm4-3a1.5 1.5 0 110-3 1.5 1.5 0 010 3z" />
    </svg>
  )
}

function AppleLogo() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  )
}

function BookIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
  )
}

function SpeakerIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="w-5 h-5"
      aria-hidden="true"
    >
      <path d="M11 5 6 9H2v6h4l5 4z" />
      <path d="M15.5 8.5a5 5 0 0 1 0 7" />
      <path d="M19 5a9 9 0 0 1 0 14" />
    </svg>
  )
}
