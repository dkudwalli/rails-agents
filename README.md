# Rails Engineer

Rails Engineer is one profile-aware plugin marketplace for Ruby on Rails development. It works with Claude Code, OpenAI Codex, Google Antigravity, and opencode. Install it once, then have its `rails-onboard` skill record the conventions your application actually uses before applying any guidance.

The pack carries both coherent guidance families:

| Profile | Guidance selected after onboarding |
|---|---|
| **Layered** | Services, queries, forms, policies, presenters, RSpec, Pundit, ViewComponent, Tailwind, PostgreSQL, and the optional SDD workflow |
| **Rich models** | Rich Active Record models, namespaced concerns, state records, CRUD controllers, Minitest + fixtures, plain CSS, and the conditional 37signals playbook |

The profile is an explicit application decision, not a migration command. Existing applications are observed and confirmed; mixed choices are allowed when recorded as deliberate divergences.

## Quick start

```text
/plugin marketplace add dkudwalli/rails-agents
/plugin install rails-engineer@rails-engineer
```

Then run `/rails-onboard` from the Rails application. It inspects the existing project, asks one profile choice at a time, previews the exact managed section, and changes nothing until you confirm. The resulting section is written to `AGENTS.md` between `rails-engineer:profile` markers.

To reconfigure later, run onboarding again. It replaces only that marked section and preserves all other `AGENTS.md` content. See the pack's [onboarding guide](rails-engineer/README.md#after-installation) and [profile template](rails-engineer/AGENTS_TEMPLATE.md).

## What you get

Rails Engineer ships 90 portable skills, static references, and an optional Spec-Kit seed. It does not ship agents, slash-command shims, hooks, or MCP servers: skills are the portable payload on every supported host.

Start work through the stable profile-aware routers: `rails-architecture`, `rails-models`, `rails-testing`, `rails-css`, `rails-database`, `rails-access`, `rails-runtime`, `rails-frontend`, `rails-tenancy`, `rails-deployment`, and `rails-workflow`. Each reads the application profile first, then selects the matching detailed skill or convention reference.

The Spec Driven Development skills are available only when onboarding selects `Workflow: sdd`. They remain opt-in and never install project files automatically. Run `sdd-init` once before the first `sdd-specify`; [Your First SDD Feature](docs/your-first-sdd-feature.md) walks through the workflow.

### Conventions

Claude Code auto-loads rules only from a project's own `.claude/rules/`; a plugin cannot make rules path-triggered automatically. The `layered-conventions` and `37signals-conventions` skills route to the profile-appropriate references when invoked. If you want deterministic path-triggered rules, copy the references for the profile your `AGENTS.md` selects:

```bash
mkdir -p .claude/rules
cp <installed-rails-engineer>/skills/layered-conventions/references/*.md .claude/rules/
# or, for a rich-models application:
cp <installed-rails-engineer>/skills/37signals-conventions/references/*.md .claude/rules/
```

## Other coding agents

**OpenAI Codex** uses the same marketplace:

```bash
codex plugin marketplace add dkudwalli/rails-agents
codex plugin add rails-engineer@rails-engineer
```

Skills appear namespaced as `rails-engineer:<skill>`.

**Google Antigravity** has no marketplace; install the pack directory:

```bash
git clone https://github.com/dkudwalli/rails-agents
agy plugin install ./rails-agents/rails-engineer
```

It copies the pack into `~/.gemini/config/plugins/`, so rerun the install after upgrading.

**opencode** needs no plugin install. Point its `skills` array to the canonical tree:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["~/src/rails-agents/rails-engineer/skills"]
}
```

Alternatively, inside a clone run `scripts/sync_skills_to_agents_dir.sh`; Antigravity and opencode both discover the resulting workspace `.agents/skills/` mirror. Restart opencode after changing an external skill source or upgrading it.

## Documentation

| Document | Purpose |
|---|---|
| [Rails Engineer pack guide](rails-engineer/README.md) | Onboarding, profile routing, and workflow availability |
| [37signals Rails Playbook](rails-engineer/docs/37signals-playbook/PLAYBOOK.md) | Conditional rich-model reference extracted from `fizzy`, `once-campfire`, and `writebook` |
| [Your First SDD Feature](docs/your-first-sdd-feature.md) | Step-by-step onboarding walkthrough for the optional SDD workflow |
| [`AGENTS.md`](AGENTS.md) | Repository authoring, portability, release, and verification guide |

For prompting technique and Model Context Protocol setup, use the official [Claude Code documentation](https://docs.claude.com/en/docs/claude-code) and [MCP specification](https://modelcontextprotocol.io); copied guidance drifts.

## Compatibility

Every pull request and a weekly scheduled run validate the portable payload plus the latest Claude Code, Codex, Antigravity, and opencode CLIs. Run `scripts/verify_plugins.sh` before a release; it checks manifests, version agreement, skill metadata, portability rules, links, and installed host validators.

## Credits

Some layered guidance adapts material from [**palkan/skills**](https://github.com/palkan/skills) by Vladimir Dementyev (MIT), including the specification-test, extraction-timing, and behavioral guidelines skills. Rich-model guidance and the vendored playbook are extracted from 37signals' open-source `fizzy`, `once-campfire`, and `writebook` applications, with a code citation behind each playbook rule.

## License

MIT
