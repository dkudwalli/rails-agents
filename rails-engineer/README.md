# Rails Engineer

Rails Engineer is one portable, profile-aware plugin. It carries both the layered Rails knowledge
set and the 37signals-inspired rich-models knowledge set without asking an application to install
two incompatible packs.

## First 10 minutes

Start in the Rails application, not in this plugin checkout.

1. Set up the application profile. In Claude Code run `/rails-onboard`. In Codex ask to use
   `rails-engineer:rails-onboard`; in Antigravity or opencode ask to use `rails-onboard`.
2. For an existing app, onboarding inspects the repository and presents an editable detected
   profile. For a new app, select the Layered, Rich Models — Fizzy-style, or Rich Models —
   ONCE-compatible starting stack; all fields remain editable.
3. Review the complete profile, resolve only missing or conflicting choices, then approve the exact
   `AGENTS.md` section. Nothing changes before that explicit confirmation.
4. Begin a task with `rails-guide`: `/rails-guide` in Claude Code, `rails-engineer:rails-guide` in
   Codex, or ask the assistant to use `rails-guide` in Antigravity or opencode. It picks the stable
   profile-aware router for the request.

The managed profile is bracketed by `rails-engineer:profile` markers. Re-running onboarding compares
the current choices and replaces only that marked section, preserving the rest of `AGENTS.md`.
[`AGENTS_TEMPLATE.md`](AGENTS_TEMPLATE.md) shows the complete section.

## Using the guidance

Use `rails-guide` whenever the right entrypoint is not obvious. It selects from the stable routers
below; each reads the profile first and then directs the assistant to the matching variant or
reference.

| Work | Router |
|---|---|
| Planning or implementation sequence | `rails-workflow` |
| Code placement or new layers | `rails-architecture` |
| Models and domain behavior | `rails-models` |
| Tests | `rails-testing` |
| CSS | `rails-css` |
| Database and migrations | `rails-database` |
| Authentication and authorization | `rails-access` |
| Jobs, cache, and realtime | `rails-runtime` |
| Views, Turbo, Stimulus, and assets | `rails-frontend` |
| Multi-tenancy | `rails-tenancy` |
| Deployment and operations | `rails-deployment` |

`layered-*` and `rich-models-*` skills are intentionally distinct where the old packs used the
same name. The vendored [37signals playbook](docs/37signals-playbook/PLAYBOOK.md) is conditional
reference material for a `rich-models` profile, not an instruction to migrate a layered app.

The `sdd-*` workflows and `specify/` seed are available only when the profile selects `Workflow:
sdd`; starter stacks use `Workflow: conventional`, so SDD is optional and never installed into an
application automatically. Use `sdd-init` and then `sdd-specify` only after selecting the opt-in
workflow.

## Host compatibility

opencode needs no plugin installation. For stable 1.x, configure the canonical tree with
`skills.paths`:

```jsonc
{
  "skills": {
    "paths": ["~/src/rails-agents/rails-engineer/skills"]
  }
}
```

The v2 `skills` array is preview-only. Inside a clone, `scripts/sync_skills_to_agents_dir.sh`
provides the version-neutral workspace `.agents/skills/` alternative.

## Release compatibility

Marketplace releases are checked from a clean worktree with `scripts/release_check.sh`. The gate
runs version, payload, renderer, profile, and release-contract checks; installed Claude Code and
Antigravity validators run as available, while missing host CLIs are reported as skipped. The same
single deterministic gate runs on GitHub Actions for pushes and pull requests without installing
host CLIs.
