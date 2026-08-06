# 13 — What they refuse to install

The omission is part of the architecture. These apps use Rails' built-ins and small application
code before adding a named layer.

---

## The evidence

This is the direct 2026-08-01 check across all three applications:

```text
$ find {fizzy,once-campfire,writebook}/app -maxdepth 1 -type d \
    \( -name services -o -name presenters -o -name serializers -o -name forms -o -name queries \) -print

$ rg -n -i 'rspec|factory_bot|shoulda|tailwind|sass|postcss|view_component|devise|pundit|cancan|sidekiq|webpack|esbuild|vite|sprockets' \
    {fizzy,once-campfire,writebook}/Gemfile

# both commands produce no output
```

The complete top-level `app/` directory lists are likewise ordinary Rails directories:

```text
fizzy:         assets channels controllers helpers javascript jobs mailers models views
once-campfire: assets channels controllers helpers javascript jobs models views
writebook:     assets channels controllers helpers javascript jobs mailers models views
```

The Gemfiles make the replacements visible: all three select Rails, importmap, Turbo, Stimulus and
Minitest-compatible Rails testing; they do not add the libraries in the table below
(`fizzy/Gemfile:5-22, 46-66`, `once-campfire/Gemfile:6-27, 48-61`,
`writebook/Gemfile:5-22, 35-49`).

## Absence is a choice, not a prohibition

| Do not add by default | Use first | Add it only when |
|---|---|---|
| RSpec / FactoryBot / shoulda | Minitest, fixtures, Rails assertions | Rails' test support cannot express a real requirement |
| `app/services`, command/query/form layers | model method or a small namespaced model concern | behaviour has a stable boundary that is neither model nor controller |
| presenters / ViewComponent | ERB partial and helper | a component has a real independent lifecycle or public API |
| Tailwind / Sass / PostCSS | plain layered CSS, custom properties, native nesting | browser support or a measured design-system need demands tooling |
| npm, Webpack, esbuild, Vite | importmap plus browser modules | a required browser dependency cannot be loaded that way |
| Devise / Pundit / CanCan | authentication and authorization concerns plus scoped model lookups | the app's identity or policy matrix has outgrown clear local code |
| Sidekiq | Solid Queue (newer Fizzy) or Resque (ONCE apps) | the selected queue cannot meet a measured operational need |
| Elasticsearch / OpenSearch | database search | database-backed search cannot satisfy the query or scale requirement |

The useful rule is: **do not create a category until the code has earned it.** `Card` shows the
preferred growth path — a regular model that includes focused, namespaced concerns
(`fizzy/app/models/card.rb:1-26`), not a parallel application layer.

## One important exception

"No service objects" is not an absolute ban. Fizzy's style guide allows a plain object when it is
the clearest domain object:

`fizzy/STYLE.md:179-183`:

> When justified, it is fine to use services or form objects, but don't treat those as special artifacts:

    Signup.new(email_address: email_address).create_identity

Do not make `app/services` a default bucket. Put `Signup` where its domain makes it discoverable,
give it a concrete API, and stop there.
