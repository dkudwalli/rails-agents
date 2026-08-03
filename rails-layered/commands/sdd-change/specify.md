---
description: Create a lightweight change specification for bug fixes and small features — skips the full SDD ceremony.
handoffs:
  - label: Generate Tasks
    agent: sdd-change:tasks
    prompt: Generate tasks for this change
    send: true
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-change-specify/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
