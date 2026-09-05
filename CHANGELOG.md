# Changelog

Notable changes to the Rails Engineer pack. Versioned manifests must agree before release.

## 3.2.0

### Changed

- Every companion-documentation path in a skill now carries the full `~/Projects/cb-dev-docs/docs/`
  prefix. Bare `reference/x.md` was one character from skill-local `references/x.md` and read as
  either; `references/` (plural, unprefixed) now means skill-local and nothing else.
- `channel-bay-testing` routes to the project's own verification gate — the `/verify` skill where
  the checkout provides one, otherwise the verification order in `AGENTS.md` — instead of restating
  a command list that drifts from it.

### Added

- `scripts/verify_plugins.sh` gained `check_doc_paths`, which enforces both contracts above.
  `check_links` only ever saw Markdown-syntax links, so every bare prose doc pointer in every skill
  was unvalidated. Resolution tries skill-local first, then the companion docs root, and skips with
  a notice when `CB_DOCS_ROOT` is absent so the gate still runs without that checkout.

### Upgrading from 2.x

3.0.0 removed the profile system, the 37signals playbook, and the ten
`37signals-conventions/references/*.md` files, but said nothing about the copies consumers had
already made. Delete these from the application checkout — they are orphaned, their relative links
point into the deleted playbook, and their content contradicts an application whose divergences are
recorded in `AGENTS.md`:

- `.claude/rules/*.md` copied from the retired `37signals-conventions/references/`. They are
  path-triggered, so they fire on ordinary edits and assert things like "there is no `spec/`, no
  `support/`" and "no service *layer*" regardless of what the application actually is.
- The `<!-- rails-engineer:profile:start -->` … `:end -->` block in the checkout's `AGENTS.md`.
  Nothing reads the profile axes now. Keep any *Deliberate divergences* list inside it — the skills
  still lean on that.
- `skillOverrides` entries in `.claude/settings*.json` naming skills 3.0.0 removed. Check the list
  against the nine shipped skills before deleting; an entry may be disabling a live *local* skill of
  the same name.

## 3.1.0

- Release the ChannelBay-focused 37signals conventions and incremental service-to-model
  modernization guidance.

## 3.0.0

### Changed

- Rebuilt Rails Engineer as a ChannelBay-only guidance pack while keeping the rails-engineer package
  name for existing Claude Code and Codex marketplace users.
- Replaced profile selection and broad Rails alternatives with nine focused ChannelBay skills.
- Restored 37signals-style rich models, resourceful CRUD, shallow jobs, and model-namespaced
  concerns as the design direction for new work and incremental refactoring of service-heavy code.
- Kept ChannelBay's PostgreSQL, Tailwind, ViewComponent, Devise, CarrierWave, Docker, and
  integration boundaries as explicit compatibility constraints.
- Made the ChannelBay checkout AGENTS.md and ~/Projects/cb-dev-docs/docs/ the canonical detailed
  guidance sources.

### Removed

- Layered and rich-model profile families, onboarding/profile rendering, SDD payload, 37signals
  playbook, and generic Rails alternatives.
- Antigravity and opencode manifests, installation guidance, and validation support.
