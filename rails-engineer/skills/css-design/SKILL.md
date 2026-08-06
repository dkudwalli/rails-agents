---
name: css-design
description: >-
  Writes plain, layered CSS with oklch custom-property tokens, dark mode, and an
  accessibility baseline — no Tailwind, Sass, or PostCSS. Use when styling views,
  building a design system, adding dark mode, defining color or spacing tokens, or
  when user mentions CSS, styling, theming, design tokens, or responsive design.
  WHEN NOT: For ERB structure and partials (use rules/views.md), for JavaScript
  behavior (use stimulus-patterns), for Turbo updates (use turbo-patterns).
license: MIT
compatibility: Rails 8.0+, Propshaft, modern browsers
---

# CSS & Design

Plain CSS served by Propshaft. No Sass, no PostCSS, no Tailwind, no CSS-in-JS.

This is not a small-app position. The largest source application carries nearly 9,000 lines of CSS
this way. The absence of tooling is what a large stylesheet looks like when the team keeps refusing
to add indirection.

## Project knowledge

**Stack:** Propshaft, one plain `.css` file per component in `app/assets/stylesheets/`, linked as a
single `stylesheet_link_tag :app`. No manifest file, no build step.

**Commands:**
```bash
ls app/assets/stylesheets/          # Alphabetical, one file per component
bin/rails assets:precompile         # Propshaft fingerprinting
```

## File organisation

One file per component, named for the component, alphabetical. There is no manifest and no import
graph to maintain.

**If a rule's correctness depends on file order, that is a layering problem.** Fix it with `@layer`,
not by renaming files to control the cascade.

> Fizzy profile only: `@layer` cascade layers, declared once in a global file:
> ```css
> @layer reset, base, components, modules, utilities, native, platform;
> ```
> Zero of the 26 stylesheets in the two ONCE applications use layers. Adopt them when the stylesheet
> count makes ordering fragile — third-party CSS then gets imported straight into a layer instead of
> fighting for specificity.

## Two-tier colour tokens

`--lch-*` hold **bare oklch components**. `--color-*` are the semantic wrappers. **Components only
ever reference `--color-*`.**

```css
:root {
  /* Tier 1: raw values, no semantics */
  --lch-black: 0% 0 0;
  --lch-white: 100% 0 0;
  --lch-blue: 55% 0.22 260;
  --lch-gray: 60% 0.01 260;

  /* Tier 2: semantics, no raw values */
  --color-text: oklch(var(--lch-black));
  --color-bg: oklch(var(--lch-white));
  --color-link: oklch(var(--lch-blue));
  --color-border: oklch(var(--lch-gray) / 0.3);
}
```

## Dark mode redefines the raw tier only

One block, a dozen values. Nothing in any component changes.

```css
:root {
  @media (prefers-color-scheme: dark) {
    --lch-black: 100% 0 0;
    --lch-white: 18% 0.01 260;
    --lch-blue: 72% 0.16 260;
  }
}

/* Explicit user override wins in both directions */
html[data-theme="dark"] { --lch-black: 100% 0 0; --lch-white: 18% 0.01 260; }
html[data-theme="light"] { --lch-black: 0% 0 0; --lch-white: 100% 0 0; }
```

Set `data-theme` with a small pre-paint inline script carrying a CSP nonce, so the page never flashes
the wrong theme.

**If you are writing a dark-mode rule inside a component, your tokens are wrong.**

## Tokens beyond colour

```css
:root {
  --spacer: 1rem;
  --spacer-half: calc(var(--spacer) / 2);
  --spacer-double: calc(var(--spacer) * 2);

  --font-size: 1rem;
  --font-family: system-ui, -apple-system, "Segoe UI", sans-serif;

  --inset-top: env(safe-area-inset-top);
}

/* A responsive type scale is the same tokens, redefined */
@media (width >= 60rem) {
  :root { --font-size: 1.125rem; }
}
```

## A component's public API is its custom properties

Variants **set variables**; they do not re-declare properties. This is what keeps specificity flat.

```css
.btn {
  --btn-bg: var(--color-bg);
  --btn-text: var(--color-text);

  background: var(--btn-bg);
  color: var(--btn-text);
  padding-block: var(--spacer-half);
  padding-inline: var(--spacer);

  &:hover { --btn-bg: color-mix(in oklch, var(--btn-bg), var(--color-text) 8%); }
}

.btn--primary { --btn-bg: var(--color-link); --btn-text: var(--color-bg); }
```

No `!important`. No specificity ladders. Pass data in as a custom property and derive the rest with
`color-mix()`.

Native nesting is for **state and context only** — `&:hover`, `&[aria-expanded="true"]`,
`@media` inside the rule. Do not nest to mirror DOM structure; BEM-ish class names do the structural
work.

Use logical properties throughout (`padding-inline`, `margin-block`, `inset-inline-start`).

## Utilities are token resolvers, not Tailwind

A utility **may only set a property to a token**. No arbitrary values, no responsive prefixes, no
generated combinatorial matrix, no `@apply`, no config file, no purge step.

```css
/* Wrap in `@layer utilities { ... }` only on the Fizzy profile; plain rules otherwise */
.txt-subtle { color: var(--color-text-subtle); }
.txt-alert  { color: var(--color-alert); }
.flex-gap   { gap: var(--spacer); }
```

**The moment you want `mt-[13px]`, write a component class.**

## Accessibility baseline

One shared block gives every interactive element a focus ring and a disabled state, using
zero-specificity `:where()` so components override without a fight:

```css
:is(a, button, input, select, textarea, summary, [tabindex]) {
  &:where(:focus-visible) {
    outline: 2px solid var(--color-link);
    outline-offset: 2px;
  }
  &:where(:disabled, [aria-disabled="true"]) {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

.for-screen-reader {
  position: absolute;
  width: 1px; height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}

@media (any-hover: hover) {
  .card:hover { --card-bg: var(--color-bg-raised); }
}
```

- Skip link first in the document
- Icons `aria-hidden` by construction — the helper that renders them should do it, not each call site
- `aria-busy` driven by actual behaviour, never decorative
- Respect `role="list"` when you remove list styling

Adopt modern CSS as it ships, backed by `allow_browser versions: :modern`. Vendor the reset as a
single file with attribution.

## Boundaries

- **Always:** One file per component, `--color-*` in components and `--lch-*` only in `:root`, dark
  mode by redefining the raw tier, variants that set custom properties, logical properties, a shared
  focus-ring block, `@media (any-hover: hover)` around hover styling
- **Ask first:** Before adopting `@layer` (check the app's profile), before adding a token tier,
  before a `!important`
- **Profile override:** if the app's `CLAUDE.md` records Tailwind, Sass, or PostCSS under
  **Deliberate divergences**, that row wins over the Never rule below — write in the idiom the app
  already runs. Removing it is `legacy-migration`'s call, not a precondition for the task at hand.
- **Never:** Add Tailwind, Sass, PostCSS, or a CSS build step; write a dark-mode rule inside a
  component; put an arbitrary value in a utility; use specificity to win an override; rely on file
  order for the cascade

See [`07-css-design.md`](../../docs/37signals-playbook/07-css-design.md).
