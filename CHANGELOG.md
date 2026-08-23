# Changelog

Notable changes to the Rails Engineer pack. Versions follow the string shared by
`.claude-plugin/marketplace.json`, `rails-engineer/.claude-plugin/plugin.json`, and
`rails-engineer/.codex-plugin/plugin.json`; the Antigravity manifest is unversioned and opencode has
no manifest.

After upgrading a Claude Code install, run `/plugin marketplace update rails-engineer`.

## Unreleased

### Added

- The release gate fails when a skill is unreachable — named by no router, named by no reachable
  skill, and not `user-invocable`. Reachability is the closure from the stable `rails-*` routers and
  every user-invocable skill, followed through skill bodies and their `references/`.
- `check_profile_gate` now covers the CSS profile axis through `TAILWIND_ONLY_SKILLS` and
  `PLAIN_CSS_ONLY_SKILLS`, alongside the existing Architecture axis.
- Payload mutation tests for both guards. Severing the only route to a skill, or stripping a profile
  boundary, now fails the suite with a named diagnostic rather than passing quietly.

### Changed

- `i18n-patterns` is routed from `rails-frontend`, `active-storage-setup` from `rails-runtime`, and
  `sdd-validate` from the end of `sdd-implement`. All three were previously unreachable.
- `dependabot-review` is `user-invocable: true`, matching its ten sibling review skills.
- `tailwind-patterns` and `css-design` declare their CSS profile and hand the other profile off by
  name. Their trigger keywords are unchanged.

### Removed

- `license: MIT` from 40 skill frontmatters. The repository `LICENSE` and all three plugin manifests
  already declare MIT, and no check read the key.

## 2.1.1

- Hardened the payload verifier against regressions in its own diagnostics.
- Made the audit and accessibility guidance profile-neutral, gating snippets by profile rather than
  assuming RSpec or axe-core.
- Hardened release automation and the compatibility documentation.

## 2.1.0

- Added `rails-guide` as the navigator that checks onboarding before selecting a stable router.
- Added `scripts/release_check.sh`, the strict pre-tag gate that requires a clean worktree and prints
  the version-derived tag.
- Enforced architecture boundaries in `scripts/verify_plugins.sh`, so a layered leaf cannot present
  itself to a rich-models application.

## 2.0.1

- Replaced the legacy per-architecture packs with the single profile-aware pack.
- Moved onboarding into the target application through `rails-onboard`, which writes only the marked
  profile section of `AGENTS.md` after explicit confirmation.

## 1.3.0

- First standalone `rails-engineer` release.
