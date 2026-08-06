# Configurable Rails Engineer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two mutually exclusive Rails packs with one profile-driven `rails-engineer` plugin.

**Architecture:** A portable `rails-onboard` skill writes a marked project profile to `AGENTS.md`. Public skills read that profile and select isolated, uniquely named guidance variants. A small Bash test harness verifies the profile renderer without source-text assertions.

**Tech Stack:** Markdown/JSON plugin payload, Bash test harness, jq, Claude/Codex/Antigravity/opencode validators.

## Global Constraints

- One portable canonical skill tree; no generated bridge trees.
- Plugin installation is non-interactive; onboarding is a user-invocable skill.
- Existing applications are detected and confirmed, never migrated automatically.
- Warned mixed choices are allowed and recorded as deliberate divergences.

---

### Task 1: Add profile-rendering contract and tests

**Files:**
- Create: `rails-engineer/scripts/render_profile.sh`
- Create: `test/render_profile_test.sh`

- [ ] Write fixture-driven failing tests for profile rendering, replacement of only the managed section, and rejection of invalid values.
- [ ] Implement the smallest profile renderer that validates choices and writes profile text to stdout.
- [ ] Run `bash test/render_profile_test.sh`.

### Task 2: Build the configurable plugin payload

**Files:**
- Create: `rails-engineer/skills/rails-onboard/SKILL.md`
- Create: `rails-engineer/skills/*/SKILL.md`
- Create: `rails-engineer/AGENTS_TEMPLATE.md`
- Create: `rails-engineer/.claude-plugin/plugin.json`
- Create: `rails-engineer/.codex-plugin/plugin.json`
- Create: `rails-engineer/plugin.json`

- [ ] Add portable onboarding instructions, profile-aware public skills, and isolated variants for the two prior guidance sets.
- [ ] Keep SDD optional and preserve the 37signals playbook as conditional reference material.
- [ ] Run the renderer tests and host manifest parsing checks.

### Task 3: Replace release/discovery integration and documentation

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.agents/plugins/marketplace.json`
- Modify: `scripts/check_versions.sh`
- Modify: `scripts/verify_plugins.sh`
- Modify: `scripts/sync_skills_to_agents_dir.sh`
- Modify: `README.md`

- [ ] Point all hosts at the single pack, revise dynamic verification, and document onboarding/reconfiguration.
- [ ] Remove retired packs only after their content has been moved into the new pack.
- [ ] Run `scripts/verify_plugins.sh`, link checks, and available host validators.
