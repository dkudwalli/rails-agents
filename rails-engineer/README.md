# Rails Engineer

Rails Engineer is one portable, profile-aware plugin. It carries both the layered Rails knowledge
set and the 37signals-inspired rich-models knowledge set without asking an application to install
two incompatible packs.

## After installation

Run the user-invocable `rails-onboard` skill from the Rails application. In Claude Code that is
`/rails-onboard`; in Codex, Antigravity, and opencode, ask the assistant to use `rails-onboard` for
the current application. The skill inspects existing project files, asks one choice at a time,
previews the exact managed section it will add to `AGENTS.md`, and changes nothing until you
confirm. For a new application it still asks each profile choice.

The managed profile is bracketed by `rails-engineer:profile` markers. Re-running onboarding compares
the current choices and replaces only that marked section, preserving the rest of `AGENTS.md`.
[`AGENTS_TEMPLATE.md`](AGENTS_TEMPLATE.md) shows the complete section.

## Using the guidance

Start with the stable router that matches the work: `rails-architecture`, `rails-models`,
`rails-testing`, `rails-css`, `rails-database`, `rails-access`, `rails-runtime`,
`rails-frontend`, `rails-tenancy`, `rails-deployment`, or `rails-workflow`. Each reads the profile
first and then directs the assistant to the matching variant or reference.

`layered-*` and `rich-models-*` skills are intentionally distinct where the old packs used the
same name. The vendored [37signals playbook](docs/37signals-playbook/PLAYBOOK.md) is conditional
reference material for a `rich-models` profile, not an instruction to migrate a layered app.

The `sdd-*` workflows and `specify/` seed are available only when the profile selects `Workflow:
sdd`; they are optional and never installed into an application automatically.
