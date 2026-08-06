---
name: sdd-change-implement
description: >-
  Execute a small change by processing all tasks sequentially from tasks.md — no
  subagents, no hooks, no checklists. Use after sdd-change-tasks, for lightweight
  changes. WHEN NOT: Full-ceremony features — use sdd-implement.
---

> **Profile routing:** Read AGENTS.md and its Rails Engineer Profile before continuing. If Workflow: conventional, stop this SDD workflow and use the project's conventional planning and delivery process. If Workflow: sdd, use every selected profile value: layered work uses layered routers and variants; rich-models work uses the stable rails-architecture, rails-models, rails-testing, rails-css, rails-frontend, and rails-access routers, which select rich-models variants. Select the test command from Testing: rspec uses bundle exec rspec; minitest uses bin/rails test. Do not follow a later example that contradicts the profile. This workflow is optional and never installs or changes project files unless it explicitly asks for confirmation.

## User Input

The user's request is whatever they wrote in the message that invoked this skill.

You **MUST** consider it before proceeding. If they gave none, continue without it.

## Outline

1. **Locate feature directory**: Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root. Parse JSON for FEATURE_DIR, FEATURE_SPEC, and TASKS paths. For single quotes in args, use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible).

2. **Validate artifacts exist**:
   - Check that FEATURE_DIR/spec.md exists. If not: "Run `sdd-change-specify` first."
   - Check that FEATURE_DIR/tasks.md exists. If not: "Run `sdd-change-tasks` first."

3. **Load context**:
   - **REQUIRED**: Read spec.md (the change spec — Problem, Proposed Change, Acceptance Criteria)
   - **REQUIRED**: Read tasks.md (the flat task list)
   - **IF EXISTS**: Read `.specify/memory/constitution.md` to respect project principles
   - **IF EXISTS**: Read `.specify/memory/lessons-learned.md` — filter to entries tagged `[phase:implement]` or `[phase:all]` and note any relevant to the current change

4. **Execute tasks sequentially**:
   - Parse all uncompleted tasks (`- [ ]` items) from tasks.md
   - For each task:
     - Execute the task as described (create, modify, or update files)
     - Follow the Rails Engineer Profile and the router for the task's layer. A layered profile may
       use services and policies; a rich-models profile keeps behavior in rich models, concerns, and
       scoped lookups. Do not create a layer the profile has not selected.
     - Mark the task as `[X]` in tasks.md immediately after completion
     - Report brief progress: task ID and what was done
   - If a task fails:
     - Provide clear error context (what failed and why)
     - Log the error to `.specify/memory/lessons-learned.md` if it represents a reusable learning (create the file with its standard header if it does not exist)
     - Halt execution and suggest next steps for manual resolution

5. **Final validation**:
   - Run `bundle exec rspec` when `Testing: rspec`, or `bin/rails test` when `Testing: minitest`,
     and report results
   - Run the application's configured lint command and report results
   - If either fails: attempt to fix the issues and re-run (max 2 attempts)
   - If still failing after retries: report the remaining issues for manual resolution

6. **Lessons learned capture**:
   - Review the implementation for noteworthy patterns or surprises
   - Present the user with:
     ```
     ## Lessons Learned

     Implementation complete. Any learnings worth recording?

     Suggested based on this session:
     - [1-2 specific observations from the implementation]

     Reply: (1) Accept suggestions, (2) Add your own, (3) Skip
     ```
   - If the user provides input, append entries to `.specify/memory/lessons-learned.md` using the entry format documented in that file
   - If the user skips, proceed without writing
   - Create the file with its standard header if it does not exist

7. **Report completion**:
   - Summary of completed tasks (count and IDs)
   - Test suite results (pass/fail count)
   - Linting results (clean or issues remaining)
