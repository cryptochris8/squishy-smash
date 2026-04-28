import { APP_STORE_URL } from '../constants/links'

export function Footer() {
  return (
    <footer className="relative z-10 mt-12 py-12 px-6 border-t border-white/10">
      <div className="max-w-6xl mx-auto grid md:grid-cols-[1.5fr_1fr_1fr_1fr] gap-8">
        <div>
          <div className="flex items-center gap-2 mb-3">
            <img
              src="/branding/squishy_smash_icon_bunny_v1.png"
              alt=""
              className="w-9 h-9 rounded-xl"
            />
            <span className="font-display text-lg font-bold">Squishy Smash</span>
          </div>
          <p className="text-white/65 text-sm leading-relaxed max-w-xs">
            A cozy, kawaii tap game by Athlete Domains. Made with too much
            pastel and a little bit of science.
          </p>
        </div>

        <FooterColumn title="Game">
          <FooterLink href="#core-loop">How it plays</FooterLink>
          <FooterLink href="#collection">Collection</FooterLink>
          <FooterLink href="#packs">Packs</FooterLink>
          <FooterLink href={APP_STORE_URL} external>App Store</FooterLink>
        </FooterColumn>

        <FooterColumn title="About">
          <FooterLink href="#parents">For parents</FooterLink>
          <FooterLink href="mailto:support@squishysmash.com">Contact</FooterLink>
          <FooterLink href="/privacy">Privacy</FooterLink>
          <FooterLink href="/support">Support</FooterLink>
        </FooterColumn>

        <FooterColumn title="Follow">
          <FooterLink
            href="https://x.com/squishy_smash"
            external
          >
            X / @squishy_smash
          </FooterLink>
        </FooterColumn>
      </div>
      <div className="max-w-6xl mx-auto mt-10 pt-6 border-t border-white/10 flex flex-col sm:flex-row justify-between items-center gap-3 text-xs text-white/50">
        <div>© {new Date().getFullYear()} Squishy Smash. All rights reserved.</div>
        <div className="flex items-center gap-1">
          <span>Made with</span>
          <span className="text-pink-300" aria-hidden="true">♡</span>
          <span>on a very small desk.</span>
        </div>
      </div>
    </footer>
  )
}

function FooterColumn({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <div>
      <div className="font-display text-xs font-bold uppercase tracking-widest text-cream-300 mb-3">
        {title}
      </div>
      <ul className="space-y-2 text-sm">{children}</ul>
    </div>
  )
}

function FooterLink({
  href,
  children,
  external = false,
}: {
  href: string
  children: React.ReactNode
  /** When true, opens in a new tab with safe `rel` attributes —
   *  used for off-site links (X, GitHub) where we don't want
   *  the user to lose their place on squishysmash.com. */
  external?: boolean
}) {
  return (
    <li>
      <a
        href={href}
        target={external ? '_blank' : undefined}
        rel={external ? 'noopener noreferrer' : undefined}
        className="text-white/75 hover:text-cream-300 transition-colors"
      >
        {children}
      </a>
    </li>
  )
}
