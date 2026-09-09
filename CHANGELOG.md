# Changelog

Notable changes to the Rails Engineer pack. Versioned manifests must agree before release.

## 3.3.0

### Fixed

- `rails-guide` now routes. Its body promised "the narrowest applicable document in
  `~/Projects/cb-dev-docs/docs/`" and then presented a table of *skill names* — skills do not live in
  that tree — and never told the agent to invoke anything. Routing is the skill's only job and it is
  the user-invocable entrypoint. The table now says Invoke, a Sources section carries the
  documentation root on its own line, and an added note resolves the operations-vs-integrations
  overlap: an operational symptom routes to `channel-bay-operations` first even when the failing
  subsystem is a provider, a queue, or the sync-progress UI.
- `channel-bay-integrations` claimed "changing **or investigating**" a provider boundary, so it
  matched every failing-Shopify-sync prompt and could fire *instead of* `rails-guide` — meaning the
  precedence note above was never loaded. Descriptions are what the host matches on, so the
  boundary has to be stated there too, not only in the router. It now defers an unproven failure to
  `channel-bay-operations`.
- Every skill opened "Read AGENTS.md" without saying what to do when that file is missing. The
  application checkout gitignores `AGENTS.md` deliberately, so it resolves on an authoring machine
  and nowhere else — a fresh clone, container, teammate, or cloud session gave all nine skills a
  dangling first instruction and the agent proceeded on recalled constraints instead. All nine now
  carry one verbatim clause: it is gitignored, ask for it rather than assume it.
- `rails-guide` states which documentation tree wins. `AGENTS.md` still points readers at the
  checkout's own numbered `docs/`, which is now a mirror; `~/Projects/cb-dev-docs/docs/` is the
  current copy.
- `channel-bay-backend` claimed permissions and workflow scope in its description but routed to
  neither document. Added `guides/staff-permissions.md` and `guides/workflows.md` — the latter was
  advertised in the pack README and reachable from no skill.
- `channel-bay-frontend` never mentioned `bin/frontend-audit --check`, which `AGENTS.md` includes in
  the verification order.
- `README.md` gave the Claude Code entrypoint as `/rails-guide`. Installed plugin skills are
  addressed as `plugin:skill`; the Codex row in the same table already said so.

### Added

- Two verifier assertions, each with a negative case in `test/plugin_payload_test.sh`.
  `check_routing` requires an invoke instruction in `rails-guide` — `check_channel_bay_scope`'s
  docs-prefix grep had passed on the very sentence that routed nowhere. `check_skills` requires any
  skill citing `AGENTS.md` to carry the absent-source clause, pinned verbatim so nine files cannot
  drift against whichever wording a single grep happened to match.
- `rails-engineer/evals/` — routing cases for `claude plugin eval`. Nothing previously verified that
  the nine descriptions fire or that overlapping ones resolve in the intended order, which for a
  plugin that is nine descriptions and prose is the product itself. Run manually; the cases cost
  model calls and are not wired into CI.

### Changed

- The `.gitignore` comment above `.agents/skills/` pointed at
  `scripts/sync_skills_to_agents_dir.sh`, a script `verify_plugins.sh` asserts must not exist. The
  ignore rule itself stays: a 2.x checkout still has that mirror's symlink tree on disk, and
  un-ignoring it dirties the worktree `release_check.sh` requires to be clean.

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
