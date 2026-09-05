# Rails Engineer

Rails Engineer 3.0 is a focused plugin for the ChannelBay application only. It supports Claude Code
and OpenAI Codex while retaining the established rails-engineer marketplace identifier.

## Install and use

| Host | Install | Start a task |
|---|---|---|
| Claude Code | Add the marketplace, then install rails-engineer at rails-engineer. | Run /rails-guide from the ChannelBay checkout. |
| OpenAI Codex | Add the marketplace, then add rails-engineer at rails-engineer. | Ask for rails-engineer:rails-guide. |

Claude Code:

    /plugin marketplace add dkudwalli/rails-agents
    /plugin install rails-engineer@rails-engineer

Codex:

    codex plugin marketplace add dkudwalli/rails-agents
    codex plugin add rails-engineer@rails-engineer

Rails Engineer ships 9 portable skills. They assume ChannelBay's Rails 7.1, Docker-first,
multi-merchant application and direct work to the project instructions plus the companion developer
documentation in ~/Projects/cb-dev-docs/docs/.

The rails-guide entrypoint applies 37signals-style Rails design to new and incrementally modernized
ChannelBay code, then routes to focused backend, frontend, async, integration, operations, testing,
and review guidance. It does not onboard arbitrary Rails applications or offer alternative
architecture stacks.

## Documentation and release

The pack guide at rails-engineer/README.md explains the skill map. The application checkout's
AGENTS.md is authoritative for active constraints; ~/Projects/cb-dev-docs/docs/ is the detailed
technical reference. This repository's AGENTS.md and CHANGELOG.md cover maintaining the plugin.

Run scripts/release_check.sh from a clean worktree before tagging a release. It validates the
Claude/Codex manifests, skill payload, links, and release contract.

## License

MIT
