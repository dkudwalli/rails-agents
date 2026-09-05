# Changelog

Notable changes to the Rails Engineer pack. Versioned manifests must agree before release.

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
