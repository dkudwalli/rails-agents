---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
handoffs: 
  - label: Analyze For Consistency
    agent: sdd:analyze
    prompt: Run a project analysis for consistency
    send: true
  - label: Implement With Specialist Agents
    agent: sdd:implement
    prompt: Start the implementation in phases, delegating each task to its specialist agent
    send: true
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-tasks/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
