---
paths:
  - "app/assets/stylesheets/**/*.css"
---

# CSS & Design Conventions (37signals)

Plain CSS served by Propshaft. No Sass, no PostCSS, no Tailwind, no CSS-in-JS — at nearly 9,000 lines
of CSS in the largest source application, so "we're too small for tooling" is not the reason.

> If the application's `CLAUDE.md` records Tailwind, Sass, or PostCSS under **Deliberate
> divergences**, that row wins over this file — style with the system the app already has.

- **One file per component**, alphabetical, no manifest, linked as a single `stylesheet_link_tag :app`
- If a rule's correctness depends on file order, that is a layering problem — fix it with `@layer`,
  not by renaming files
- **Two-tier colour tokens.** `--lch-*` hold bare oklch components; `--color-*` are the semantic
  wrappers. Components only ever reference `--color-*`
- **Dark mode redefines the raw tier only** — one `@media (prefers-color-scheme: dark)` block inside
  `:root` swapping a dozen values. If you are writing a dark-mode rule inside a component, your tokens
  are wrong. Add `html[data-theme="dark"]` / `html:not([data-theme])` for an explicit override, with a
  pre-paint inline script carrying a CSP nonce
- Design tokens beyond colour: logical relative spacing with `-half`/`-double` via `calc()`, a type
  scale made responsive by redefining tokens inside a media query, system font stacks, safe-area insets
- **A component's public API is the custom properties it exposes.** Variants set variables; they do
  not re-declare properties. No `!important`, no specificity ladders
- Pass data in as a custom property and derive the rest with `color-mix()`
- Native nesting for state and context only — not to mirror DOM structure. BEM-ish class names do the
  structural work
- Utilities exist, but **a utility may only set a property to a token**. No arbitrary values, no
  responsive prefixes, no generated matrix. The moment you want `mt-[13px]`, write a component class
- Logical properties throughout. Adopt modern CSS as it ships, backed by `allow_browser versions: :modern`
- Vendor the reset as a single file with attribution

## Accessibility baseline

- One shared `:is(...)` block gives every interactive element a focus ring and a disabled state, using
  zero-specificity `:where()` so components can override without a fight
- Skip link first in the document; semantic HTML and keyboard access are not optional
- Guard hover styling with `@media (any-hover: hover)`
- `.for-screen-reader` for visually-hidden text; icons `aria-hidden` by construction; `aria-busy`
  driven by actual behaviour; respect `role="list"`

> Fizzy profile only: `@layer` cascade layers declared once
> (`@layer reset, base, components, modules, utilities, native, platform;`). Zero of the 26 stylesheets
> in Campfire and Writebook use them. Adopt layers when the stylesheet count makes ordering fragile.

See [`07-css-design.md`](../../../docs/37signals-playbook/07-css-design.md).
