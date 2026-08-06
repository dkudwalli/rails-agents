---
name: sdd-init
description: >-
  Install or upgrade the Spec-Kit scaffolding the sdd-* skills depend on, copying
  the seed out of the installed plugin into the project's .specify directory. Use
  once per project before the first sdd-specify, and again after upgrading the
  Rails Engineer plugin.
  WHEN NOT: Writing a spec, plan, or tasks — those are sdd-specify, sdd-plan, and
  sdd-tasks, and they assume .specify already exists.
user-invocable: true
---

> **Profile gate:** This workflow is optional. Read AGENTS.md first and continue only when its Rails Engineer Profile records Workflow: sdd. It never installs or changes project files unless this skill explicitly asks for confirmation.

# Install the Spec-Kit scaffolding

Install or upgrade the Spec-Kit scaffolding the `sdd-*` and `sdd-change-*` skills depend on.

Run this once per project before the first `sdd-specify`. Re-run it after upgrading the
Rails Engineer plugin to pick up new scripts and templates.

## Why this exists

Spec-Kit locates its own root by walking **upward from the working directory looking for a literal
`.specify` directory**, then reads templates from `$repo_root/.specify/templates/`
(`specify/scripts/bash/common.sh`). It is designed to live in the consumer's project root and write
`$repo_root/specs/`, so it cannot be run in place from the plugin directory. This skill copies the
seed out of the plugin and into the project, which is why every `.specify/...` path in the other SDD
skills is project-relative and correct as written.

## Steps

1. Resolve the project root and refuse to continue if this is not a git repository:

   ```bash
   ROOT=$(git rev-parse --show-toplevel) || { echo "Not a git repository — run sdd-init from inside your project."; exit 1; }
   ```

2. Resolve the plugin's own directory. **You know the absolute path you loaded this `SKILL.md`
   from** — the seed lives one level above it, at `<that directory>/../../`. Substitute that real
   path when you run the commands below; do not rely on a host variable, because the plugin-root
   variable differs per host and is empty on most of them.

   Set it inline in the same command, and keep the trailing `;` — some hosts flatten a fenced block
   onto one line, which would otherwise turn the assignment into an environment prefix and expand it
   to empty:

   ```bash
   SKILL_DIR="<absolute path to the loaded sdd-init skill directory>"; PLUGIN_ROOT="$SKILL_DIR/../.."; ls "$PLUGIN_ROOT/specify"
   ```

   If that listing fails, stop and report it rather than copying nothing.

3. Copy the seed. **The idempotency differs per subtree — this is the whole reason this is a skill
   and not a one-line `cp -R`:**

   ```bash
   SKILL_DIR="<absolute path to the loaded sdd-init skill directory>"; PLUGIN_ROOT="$SKILL_DIR/../.."; \
   ROOT=$(git rev-parse --show-toplevel); \
   mkdir -p "$ROOT/.specify" && \
   cp -R "$PLUGIN_ROOT/specify/scripts"   "$ROOT/.specify/" && \
   cp -R "$PLUGIN_ROOT/specify/templates" "$ROOT/.specify/" && \
   { [ -e "$ROOT/.specify/memory" ] || cp -R "$PLUGIN_ROOT/specify/memory" "$ROOT/.specify/"; } && \
   { [ -f "$ROOT/.specify/init-options.json" ] || cp "$PLUGIN_ROOT/specify/init-options.json" "$ROOT/.specify/"; } && \
   chmod +x "$ROOT/.specify/scripts/bash/"*.sh
   ```

   `scripts/` and `templates/` are always refreshed — that is the upgrade path. `memory/` and
   `init-options.json` are copied only when absent, because they accumulate project content that
   must never be clobbered.

   Note that `cp -R` over `templates/` merges rather than deletes, so any
   `.specify/templates/overrides/` the project has added survives the refresh.

   `memory/constitution.md` and `memory/lessons-learned.md` are authored content — the constitution
   is written by `sdd-constitution`, and lessons accumulate across features. Overwriting either
   destroys project history, which is why both are guarded.

4. Report what happened: which paths were refreshed, which were left alone because they already
   existed, and whether `.specify/memory/constitution.md` exists yet. If it does not, tell the
   developer to run `sdd-constitution` before `sdd-specify`.

5. Suggest committing `.specify/` — it is project configuration, not build output.
