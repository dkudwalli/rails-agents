# The 37signals Rails Playbook

Prescriptive Rails rules extracted from three 37signals applications, with a citation into real
code behind every rule.

**Sources** (all read at `~/Projects`, observed **2026-08-01**):

| | `fizzy` | `once-campfire` | `writebook` |
|---|---|---|---|
| What it is | Kanban board / issue tracker | Chat | Books & docs publishing |
| Ruby | 3.4.8 | 3.4.5 | 3.4.7 |
| Rails | `github: rails/rails`, branch `main` | `github: rails/rails`, branch `main` | `github: rails/rails` |
| Ruby code | 705 files / 35,478 lines | 225 / 7,451 | 138 / 4,292 |
| ERB | 330 / 5,895 | 78 / 2,228 | 74 / 1,725 |
| JS | 89 / 4,182 | 74 / 3,956 | 32 / 1,095 |
| CSS | 64 / 8,887 | 26 / 3,339 | 26 / 2,564 |
| Database | SQLite **or** MySQL (Trilogy) | SQLite | SQLite |
| Jobs | Solid Queue | Resque + resque-pool | Resque + resque-pool |
| Cache / Cable | Solid Cache / Solid Cable | Redis | Redis |
| Deploy | Kamal + Docker | Docker (ONCE) | Docker (ONCE) |
| Written style guide | `STYLE.md` + `AGENTS.md` | none | narrow `AGENTS.md` |
| Last commit seen | 2026-07-28 | 2026-07-28 | 2026-07-28 |

Counts are `find app lib config test -name "*.ext"` line totals.

## How to read this

Every rule holds in **all three applications unless it carries a `> Divergence:` note.** Divergence
notes are only written where a search proved the difference, so their absence means the practice was
found consistently.

Citations look like `fizzy/app/models/card.rb:2-4` and are relative to `~/Projects` **as those
applications existed on the observed date**. Excerpts are verbatim, not paraphrased. Those paths are
provenance, not links — nothing in this repository resolves them, so do not try. The plugin's skills
and conventions references cite *these documents* instead (`13-absences.md`), so every citation a
skill makes has a resolvable target.

These 24 documents are vendored inside the `rich-models` plugin, and the plugin cites them by
relative path from the same plugin root, so installing the plugin brings the playbook with it. There
is nothing separate to copy.

## Two warnings before you apply any of this

**1. All three track edge Rails.** Every `Gemfile` pins Rails to git, not a released version. Features
used here — `params.expect`, `ActiveSupport::ContinuousIntegration`, `broadcasts_refreshes` with
morphing, `resource`-level `etag` blocks, UUIDv7 primary keys — may not exist or may behave
differently on the Rails version you are running. Check before copying.

**2. The three applications disagree with each other, and the newest one wins.** Campfire and
Writebook were built for ONCE (self-hosted, single-tenant, Redis-backed). Fizzy is newer, multi-tenant,
and has moved to the Solid trifecta with no Redis at all. Where they conflict, `14-divergences.md`
records both and names the direction of travel. Don't average them.

## The documents

| | | |
|---|---|---|
| [`PLAYBOOK.md`](PLAYBOOK.md) | **Condensed ruleset** | The whole playbook as rules, no prose — copy into your repo's `AGENTS.md` / `AGENTS.md` |
| [`01-philosophy.md`](01-philosophy.md) | Philosophy | Vanilla Rails, conceptual compression, why there is no service layer |
| [`02-ruby-style.md`](02-ruby-style.md) | Ruby style | `STYLE.md`'s rules verified against all three, plus the conventions it doesn't mention |
| [`03-models.md`](03-models.md) | Models | The namespaced-concern idiom, `delegated_type`, `Current`, scopes, callbacks |
| [`04-controllers-routing.md`](04-controllers-routing.md) | Controllers & routing | Domain nouns as resources, REST with no custom actions, `*Scoped` concerns, `direct`/`resolve` |
| [`05-views-helpers.md`](05-views-helpers.md) | Views & helpers | Small partials, helpers instead of presenters, layout structure, jbuilder |
| [`06-hotwire-javascript.md`](06-hotwire-javascript.md) | Hotwire & JS | No build step, Stimulus conventions, Turbo streams/morphing, JS directory layout |
| [`07-css-design.md`](07-css-design.md) | CSS & design | Plain CSS, oklch token layering, dark mode, one file per component, a11y baseline |
| [`08-jobs-async.md`](08-jobs-async.md) | Background work | `_later`/`_now`, shallow jobs, recurring tasks |
| [`09-data-search.md`](09-data-search.md) | Data & search | Schema conventions, UUID keys, in-database full-text search |
| [`10-auth-security.md`](10-auth-security.md) | Auth & security | Session/Identity, magic links, passkeys, the security tooling in CI |
| [`11-testing.md`](11-testing.md) | Testing | Minitest + fixtures, never factories, test helper concerns, system tests |
| [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) | Tooling, CI, deploy | `bin/setup`, `config/ci.rb`, RuboCop omakase, Kamal, Docker, Thruster |
| [`13-absences.md`](13-absences.md) | What they refuse to install | The libraries and directories that are conspicuously missing, and what replaces each |
| [`14-divergences.md`](14-divergences.md) | Where the three disagree | Comparison table and direction of travel |
| [`15-review-checklist.md`](15-review-checklist.md) | Review checklist | What to check on a PR, distilled from everything above |
| [`16-configuration-lifecycle.md`](16-configuration-lifecycle.md) | Configuration & lifecycle | Initializers, request context, environment policy, framework extension |
| [`17-realtime-notifications.md`](17-realtime-notifications.md) | Realtime & notifications | Turbo, Cable, mail, push, and delivery preferences |
| [`18-content-storage-portability.md`](18-content-storage-portability.md) | Content & storage | Action Text, Active Storage, authorization, exports, imports |
| [`19-integrations-webhooks.md`](19-integrations-webhooks.md) | Integrations & webhooks | Delivery records, SSRF boundary, signatures, bot responses |
| [`20-performance-operability.md`](20-performance-operability.md) | Performance & operability | Query shape, caching, logs, health checks, bounded work |
| [`21-new-app-decisions.md`](21-new-app-decisions.md) | New app decisions | Choose an ONCE-compatible or Fizzy profile without accidental hybrids |

Read `01` → `04` first; they carry the ideas the rest depend on.

## Framework context

37signals code establishes the rules in this playbook. The official Rails Guides are linked only
where they clarify framework behavior or version compatibility: [configuration](https://guides.rubyonrails.org/configuring.html),
[Action Cable](https://guides.rubyonrails.org/action_cable_overview.html),
[Action Mailer](https://guides.rubyonrails.org/action_mailer_basics.html),
[Active Storage](https://guides.rubyonrails.org/active_storage_overview.html), and
[Action Text](https://guides.rubyonrails.org/action_text_overview.html).

## Keeping this current

These are snapshots of someone else's extraction. **Re-vendor them rather than editing in place** —
local edits drift from the source with nothing to detect it.

When re-vendoring, the contract the extraction holds itself to: the prescriptive sources are
`fizzy`, `once-campfire`, and `writebook` only, and the Rails Guides explain API behaviour without
ever creating a rule; every excerpt is quoted exactly and cites a meaningful line range; a rule is
shared only after all three applications were checked, otherwise it carries a `> Divergence:` note
naming the applications and the product reason. Bump the observation date above only after that
review.
