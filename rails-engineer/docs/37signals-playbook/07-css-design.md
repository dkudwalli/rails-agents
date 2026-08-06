# 07 — CSS & design

Plain CSS files served by Propshaft. No Sass, no PostCSS, no Tailwind, no CSS-in-JS, no build step —
and 8,887 lines of it in fizzy, so this is not a matter of the apps being too small to need tooling.

---

## One file per component, alphabetical, no manifest

`fizzy/app/assets/stylesheets/` holds 64 flat files named after what they style: `avatars.css`,
`buttons.css`, `card-columns.css`, `cards.css`, `dialog.css`, `filters.css`, `flash.css`, `inputs.css`,
`nav.css`, `notifications.css`, `pagination.css`, `panels.css`, `popup.css`, `reactions.css`,
`search.css`, `steps.css`, `toggles.css`, `tooltips.css`, `trays.css`, `utilities.css`. Campfire and
writebook have 26 each, same convention.

They are linked as one tag. `fizzy/app/views/layouts/shared/_head.html.erb:20`:

```erb
  <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
```

`once-campfire/app/views/layouts/application.html.erb:24` and
`writebook/app/views/layouts/application.html.erb:28`:

```erb
    <%= stylesheet_link_tag :all, "data-turbo-track": "reload" %>
```

There is no `application.css` with `@import` statements, and no manifest listing the files. Adding a
component means adding a file.

**Consequence — load order is alphabetical, so the foundations are named to sort first.** Campfire and
writebook prefix the reset with an underscore: `_reset.css` (`_` sorts before lowercase letters).
Fizzy uses `_global.css` for the same reason and solves ordering properly with cascade layers instead.

**Rule: if a rule's correctness depends on file order, you have a layering problem — fix it with
`@layer`, not by renaming files.**

## Cascade layers declared once, up front

`fizzy/app/assets/stylesheets/_global.css:1`:

```css
@layer reset, base, components, modules, utilities, native, platform;
```

Then every file opens by declaring which layer it belongs to:

```css
@layer reset {        /* fizzy/app/assets/stylesheets/reset.css:1 */
@layer base {         /* fizzy/app/assets/stylesheets/base.css:1 */
@layer components {   /* fizzy/app/assets/stylesheets/buttons.css:1, cards.css:1, theme-switcher.css:1 */
@layer utilities {    /* fizzy/app/assets/stylesheets/utilities.css:1 */
```

60 of fizzy's 64 stylesheets use `@layer`. Specificity fights disappear: a utility always beats a
component because of where it sits in the layer order, not because of how many classes are in the
selector. Third-party CSS is imported straight into a layer —
`fizzy/app/assets/stylesheets/lexxy.css:1-3`:

```css
@import url("lexxy-variables.css") layer(base);
@import url("lexxy-content.css") layer(base);
@import url("lexxy-editor.css") layer(base);
```

> Divergence: **0 of 26** stylesheets in campfire and writebook use `@layer` — they predate it. This is
> the clearest "newest wins" case in the CSS. Use layers.

## Two-tier colour tokens: raw values, then semantic names

`writebook/app/assets/stylesheets/colors.css:1-35` (campfire's is near-identical):

```css
:root {
  /* Named color values */
  --lch-black: 0% 0 0;
  --lch-white: 100% 0 0;
  --lch-gray-light: 96% 0.005 96;
  --lch-gray: 92% 0.005 96;
  --lch-gray-dark: 75% 0.005 96;
  --lch-blue: 54% 0.15 255;
  --lch-blue-light: 95% 0.03 255;
  --lch-blue-dark: 80% 0.08 255;
  --lch-orange: 70% 0.2 44;
  --lch-red: 51% 0.2 31;
  --lch-green: 65.59% 0.234 142.49;
  --lch-green-light: 95% 0.03 142.49;
  --lch-always-black: 0% 0 0;
  --lch-always-white: 100% 0 0;
  --lch-yellow: 92.62% 0.1 91.5;

  /* Abstractions */
  --color-negative: oklch(var(--lch-red));
  --color-positive: oklch(var(--lch-green));
  --color-positive-light: oklch(var(--lch-green-light));
  --color-bg: oklch(var(--lch-white));
  --color-ink: oklch(var(--lch-black));
  --color-ink-reversed: oklch(var(--lch-white));
  --color-link: oklch(var(--lch-blue));
  --color-subtle-light: oklch(var(--lch-gray-light));
  --color-subtle: oklch(var(--lch-gray));
  --color-subtle-dark: oklch(var(--lch-gray-dark));
  --color-selected: oklch(var(--lch-blue-light));
  --color-selected-dark: oklch(var(--lch-blue-dark));
  --color-marker: oklch(var(--lch-orange));
  --color-always-black: oklch(var(--lch-always-black));
  --color-always-white: oklch(var(--lch-always-white));
  --color-highlight: oklch(var(--lch-yellow));
```

The two tiers are the whole trick:

1. `--lch-*` hold **bare oklch components** (`54% 0.15 255`), not colour functions.
2. `--color-*` are **semantic**, wrapping a raw token in `oklch(...)`.

Components only ever use `--color-*`. Nothing in a component file names a hue.

Naming is `--color-<role>` with `-light` / `-dark` modifiers: `--color-bg`, `--color-ink`,
`--color-link`, `--color-subtle`, `--color-selected`, `--color-negative`, `--color-positive`,
`--color-marker`, `--color-highlight`. Ink and background rather than black and white — so
`--color-ink` can be white in dark mode without lying. `--color-always-black` /
`--color-always-white` exist for the handful of things that must not invert.

## Dark mode redefines the raw tier only

`writebook/app/assets/stylesheets/colors.css:37-50`:

```css
  /* Redefine named color values for dark mode */
  @media (prefers-color-scheme: dark) {
    --lch-black: 100% 0 0;
    --lch-white: 0% 0 0;
    --lch-gray-light: 25.2% 0 0;
    --lch-gray: 30.12% 0 0;
    --lch-gray-dark: 44.95% 0 0;
    --lch-blue: 72.25% 0.16 248;
    --lch-blue-light: 28.11% 0.053 248;
    --lch-blue-dark: 42.25% 0.07 248;
    --lch-red: 73.8% 0.184 29.18;
    --lch-green: 75% 0.21 141.89;
    --lch-green-light: 28.11% 0.02 142.49;
    --lch-yellow: 40.9% 0.06 88.9;
```

One `@media` block, inside `:root`, swapping ~12 values. No `.dark` variants on components, no second
theme file, no duplicated rules. `--lch-black: 100% 0 0` — "black" becomes white; the semantic layer
above it doesn't change at all, so `--color-ink` keeps meaning "text colour".

Note the dark values are not mechanical inversions: greys compress (`96%` → `25.2%`), blues get
lighter and shift hue (`255` → `248`), reds lighten a lot (`51%` → `73.8%`). That's a designer
adjusting for perceptual contrast, which oklch makes tractable.

**Rule: put dark mode in the token layer. If you're writing a dark-mode rule inside a component, your
tokens are wrong.**

### The explicit-override pattern for a user theme toggle

Fizzy adds a manual switch on top of the media query. Every dark-mode rule appears twice —
`fizzy/app/assets/stylesheets/buttons.css:31-39`:

```css
    html[data-theme="dark"] & {
      --btn-hover-brightness: 1.25;
    }

    @media (prefers-color-scheme: dark) {
      html:not([data-theme]) & {
        --btn-hover-brightness: 1.25;
      }
    }
```

`html[data-theme="dark"]` wins when the user has chosen; `html:not([data-theme])` inside the media
query is the automatic case. The attribute is set before first paint by an inline script —
`fizzy/app/views/layouts/_theme_preference.html.erb:1-6`, in full:

```erb
<%= javascript_tag nonce: true do %>
  const theme = localStorage.getItem("theme")
  if (theme && theme !== "auto") {
    document.documentElement.dataset.theme = theme
  }
<% end %>
```

Rendered in `<head>` before the stylesheet (`_head.html.erb:19-20`) so there is no flash of the wrong
theme, and with `nonce: true` for CSP.

The `<head>` also declares support to the browser (`fizzy/app/views/layouts/shared/_head.html.erb:8-10`):

```erb
  <meta name="color-scheme" content="light dark">
  <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#0d181d" media="(prefers-color-scheme: dark)">
```

## Design tokens beyond colour

`fizzy/app/assets/stylesheets/_global.css:3-69` — the whole design system in one `:root`:

```css
:root {
  /* Insets - The mobile apps may inject their own custom insets based on native elements on screen, like a floating navigation */
  --custom-safe-inset-top: var(--injected-safe-inset-top, env(safe-area-inset-top, 0px));

  /* Spacing */
  --inline-space: 1ch;
  --inline-space-half: calc(var(--inline-space) / 2);
  --inline-space-double: calc(var(--inline-space) * 2);
  --block-space: 1rem;
  --block-space-half: calc(var(--block-space) / 2);
  --block-space-double: calc(var(--block-space) * 2);

  /* Text */
  --font-sans: "Adwaita Sans", -apple-system, BlinkMacSystemFont, "Segoe UI Variable Fizzy", "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
  --font-serif: ui-serif, serif;
  --font-mono: ui-monospace, monospace;

  --text-xx-small: 0.55rem;
  --text-x-small: 0.75rem;
  --text-small: 0.85rem;
  --text-normal: 1rem;
  --text-medium: 1.1rem;
  --text-large: 1.5rem;
  --text-x-large: 1.8rem;
  --text-xx-large: 2.5rem;

  @media (max-width: 639px) {
    --text-xx-small: 0.65rem;
    --text-x-small: 0.85rem;
    --text-small: 0.95rem;
    --text-normal: 1.1rem;
    --text-medium: 1.2rem;
  }
```

Observations worth stealing:

- **Spacing is logical and relative**: `--inline-space: 1ch` (scales with the font),
  `--block-space: 1rem`, with `-half` / `-double` derived via `calc()`. Two axes, three sizes each —
  not a 12-step scale.
- **The type scale is responsive by redefining the tokens** inside a `@media`, not by restating
  `font-size` per component. On small screens everything gets slightly larger, in one place.
- **System font stacks.** `ui-serif`, `ui-monospace`, `-apple-system` — one webfont in fizzy
  (`font-face.css`), none in the others.
- Tokens for shadows, borders, focus rings, component sizes (`--btn-size`, `--footer-height`,
  `--tray-size: clamp(12rem, 25dvw, 24rem)`), animation durations, and named easing curves
  (`--ease-out-expo`, `--ease-out-overshoot`) with a source comment.
- **Safe-area insets are tokens with a native override** — `var(--injected-safe-inset-top, env(safe-area-inset-top, 0px))`
  lets the native app inject a value, falling back to the browser's.

## Components expose their own custom properties as an API

`fizzy/app/assets/stylesheets/buttons.css:2-23`:

```css
  .btn {
    --icon-size: var(--btn-icon-size, 1.3em);
    --btn-border-radius: 99rem;
    --btn-hover-brightness: 0.9;

    align-items: center;
    background-color: var(--btn-background, var(--color-canvas));
    border-radius: var(--btn-border-radius);
    border: var(--btn-border-size, 1px) solid var(--btn-border-color, var(--color-ink-light));
    color: var(--btn-color, var(--color-ink));
    cursor: pointer;
    display: inline-flex;
    font-size: 1em;
    font-weight: var(--btn-font-weight, 600);
    gap: var(--btn-gap, 0.5em);
    justify-content: center;
    padding: var(--btn-padding, 0.5em 1.1em);
```

Every visual property reads `var(--btn-*, <default>)`. A variant then sets the variables instead of
overriding declarations — `fizzy/app/assets/stylesheets/theme-switcher.css:10-27`:

```css
  .theme-switcher__btn {
    --btn-background: var(--color-ink-lightest);
    --btn-border-radius: 0.4em;
    --btn-border-size: 0;
    --btn-gap: 0.1lh;
    --btn-padding: 1em;
    --icon-size: 2em;

    column-gap: var(--inline-space);
    flex: 1;
    flex-direction: column;
    position: relative;
    white-space: nowrap;

    &:has(input:checked) {
      --btn-background: var(--color-selected);
      --btn-color: var(--color-ink);
    }
  }
```

No `!important`, no `.btn.btn--theme-switcher` specificity ladder, no `:where()` tricks — the variant
just declares values.

**Rule: a component's variable declarations at the top are its public interface. Variants set
variables; they don't re-declare properties.**

Where a value must be computed from data, Ruby sets the custom property inline — see
`card_article_tag` in [`05-views-helpers.md`](05-views-helpers.md), which emits
`style="--card-color: …"`, and the CSS derives everything else from it
(`fizzy/app/assets/stylesheets/cards.css:5-16`):

```css
  .card {
    --avatar-size: 2.75em;
    --card-bg-color: color-mix(in srgb, var(--card-color) 4%, var(--color-canvas));
    --card-content-color: color-mix(in srgb, var(--card-color) 30%, var(--color-ink));
    --card-text-color: color-mix(in srgb, var(--card-color) 75%, var(--color-ink));
    --card-border: 1px solid color-mix(in srgb, var(--card-color) 33%, var(--color-ink-inverted));
```

One value from the database, five derived colours from `color-mix()`. **Rule: pass data into CSS as a
custom property; derive the rest in CSS.**

## Native CSS nesting, used for state and context only

Nesting appears everywhere but stays shallow, and it's used for:

- pseudo-classes and states — `&:hover`, `&[disabled]`, `&:has(input:checked)`
- media queries inside the rule — `@media (max-width: 479px) { … }`
- ancestor context via `&` on the right — `html[data-theme="dark"] & { … }`
- child element overrides — `.card { .popup { inline-size: 260px; } }`
  (`fizzy/app/assets/stylesheets/cards.css:40-42`)

The heaviest-nested file in fizzy has 30 `&:` selectors across the whole file. Nesting is not used to
mirror DOM structure — the class naming already does that.

## Class naming: BEM-ish, and it does the structural work

`card`, `card__header`, `card__body`, `card__footer`, `card__content`, `card--postponed`,
`card--active`, `card-perma__actions`, `card-perma__actions--left`, `message__day-separator`,
`message__avatar`, `message__body-content`, `message--emoji`, `header__skip-navigation`,
`theme-switcher__btn`, `flash__inner`.

`block__element--modifier`, one level of element. Because the class name states the structure, the CSS
does not need descendant selectors, which is what keeps specificity flat.

## Utilities exist, and they are tokens made addressable

`fizzy/app/assets/stylesheets/utilities.css:1-38`:

```css
@layer utilities {
  /* Text */
  .txt-xx-small { font-size: var(--text-xx-small); }
  .txt-x-small { font-size: var(--text-x-small); }
  .txt-small { font-size: var(--text-small); }
  .txt-normal { font-size: var(--text-normal); }
  .txt-medium { font-size: var(--text-medium); }
  .txt-large { font-size: var(--text-large); }

  .txt-align-center { text-align: center; }
  .txt-align-start { text-align: start; }
  .txt-align-end { text-align: end; }

  .txt-current { color: currentColor; }
  .txt-ink { color: var(--color-ink); }
  .txt-reversed { color: var(--color-ink-inverted); }
  .txt-negative { color: var(--color-negative); }
  .txt-positive { color: var(--color-positive); }
  .txt-subtle { color: var(--color-ink-dark); }
  .txt-alert { color: var(--color-marker); }
  .txt-undecorated { text-decoration: none; }
  .txt-underline { text-decoration: underline; }
  .txt-tight-lines { line-height: 1.2; }
  .txt-nowrap { white-space: nowrap; }
  .txt-balance { text-wrap: balance; }
  .txt-break { word-break: break-word; }
```

This is not Tailwind. Every utility is one hand-written rule that resolves a **token**, the names are
domain words (`txt-subtle`, `txt-alert`), there are no arbitrary values, no responsive prefixes, and
no generated combinatorial matrix. One file, hand-maintained, in the `utilities` layer so it wins over
components.

**Rule: a utility may only set a property to a design token. The moment you want `mt-[13px]`, write a
component class.**

## Logical properties throughout

`inline-size`, `block-size`, `padding-inline`, `padding-block`, `margin-inline`, `text-align: start` /
`end`, `--inline-space` / `--block-space`. Physical `left`/`right`/`width` are rare. That is what makes
`dir="auto"` on user content (`once-campfire/app/views/messages/_presentation.html.erb:1`) work for
RTL languages without a separate stylesheet.

## Modern CSS is used as soon as it ships

Collected from the files above: `oklch()`, `color-mix()`, `@layer`, native nesting, `&`, `:has()`,
`:is()`, `:where()`, `text-wrap: balance`, `aspect-ratio`, `clamp()`, `dvw`/`lh`/`ch` units,
`interpolate-size: allow-keywords` (`fizzy/app/assets/stylesheets/base.css:17`), `@media (any-hover: hover)`,
view transitions (`view-transition-name` set in `card_article_tag`), `<dialog>` styling,
`env(safe-area-inset-*)`.

`writebook/app/controllers/application_controller.rb:4` records the browser floor this buys:

```ruby
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
```

**Rule: `allow_browser versions: :modern` first, then use the platform.** Deciding the floor once is
what makes it safe to skip prefixes, polyfills and fallbacks everywhere else.

## The reset is 40 lines of someone else's, vendored

`fizzy/app/assets/stylesheets/reset.css:1-12` (and `writebook/app/assets/stylesheets/_reset.css:1-11`,
`once-campfire/app/assets/stylesheets/_reset.css`):

```css
@layer reset {
  /*
  * Modern CSS Reset
  * @link https://github.com/hankchizljaw/modern-css-reset
  */

  /* Box sizing rules */
  *,
  *::before,
  *::after {
    box-sizing: border-box;
  }
```

Copied in with attribution, not added as a dependency.

## Accessibility is in the shared rules, not per-component

`fizzy/app/assets/stylesheets/base.css:35-53`:

```css
  :is(a, button, input, textarea, .switch, .btn) {
    transition: 100ms ease-out;
    transition-property: background-color, border-color, box-shadow, outline;
    touch-action: manipulation;

    /* Keyboard navigation */
    &:where(:focus-visible) {
      border-radius: 0.25ch;
      outline: var(--focus-ring-size) solid var(--focus-ring-color);
      outline-offset: var(--focus-ring-offset);
    }

    /* Default disabled styles */
    &:where([disabled]) {
      cursor: not-allowed;
      opacity: 0.5;
      pointer-events: none;
    }
  }
```

One rule gives every interactive element a focus ring and a disabled state. `:where()` keeps
specificity at zero so components can override without a fight.

The rest of the baseline:

- **Skip link first in the DOM** — `fizzy/app/views/layouts/application.html.erb:15`.
- **`@media (any-hover: hover)` guards every hover effect** (`buttons.css:25`) so touch devices don't
  get stuck hover states.
- **`.for-screen-reader`** for visually-hidden labels, used on icon-only buttons —
  `writebook/app/views/books/index.html.erb:16`:
  ```erb
        <span class="for-screen-reader">Manage people and settings</span>
  ```
- **Icons are `aria-hidden` by construction** — `icon_tag` sets it
  (`fizzy/app/helpers/application_helper.rb:10`), as does `image_tag … aria: { hidden: true }`.
- **`aria-busy` driven by behaviour**, set by the Stimulus controller that submits the form
  (`fizzy/app/javascript/controllers/auto_submit_controller.js:24-30`), and styled from it:
  `form[aria-busy] &:disabled` (`buttons.css:50`).
- **`role="list"` respected** — `:where(ul, ol):where([role="list"])` strips list styling only where the
  role is explicit (`fizzy/app/assets/stylesheets/base.css:69-73`), which keeps semantics intact for
  screen readers.
- Semantic elements in templates: `<section>`, `<header>`, `<main>`, `<footer>`, `<figure>`, `<nav>`,
  `<h2>`/`<h3>`, `<kbd>`, `<dialog>`.

## Per-account custom CSS, safely

All three let an account inject CSS. It goes through a helper that emits a `<style>` tag
(`writebook/app/helpers/application_helper.rb:10-14`):

```ruby
  def custom_styles_tag
    if custom_styles = Current.account&.custom_styles
      tag.style(custom_styles.to_s.html_safe, data: { turbo_track: "reload" })
    end
  end
```

with a dedicated `Accounts::CustomStylesController` (`resource :custom_styles, only: %i[ edit update ]`
in all three routes files). Because components are token-driven, an account can restyle a lot by
setting `--color-*` alone.

## Related

- [`05-views-helpers.md`](05-views-helpers.md) — the helpers that emit these classes and inline custom
  properties.
- [`06-hotwire-javascript.md`](06-hotwire-javascript.md) — behaviour that stays in CSS
  (`animationend`, `:has()`, `pointer-events`) instead of moving to JS.
- [`14-divergences.md`](14-divergences.md) — `@layer` is fizzy-only; that's the direction of travel.
