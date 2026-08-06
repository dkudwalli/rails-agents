---
name: sdd-change-tasks
description: Generate a flat task list (3-8 tasks) for a small change based on the change spec.
---

> **Profile routing:** Read AGENTS.md and its Rails Engineer Profile before continuing. If Workflow: conventional, stop this SDD workflow and use the project's conventional planning and delivery process. If Workflow: sdd, use every selected profile value: layered work uses layered routers and variants; rich-models work uses the stable rails-architecture, rails-models, rails-testing, rails-css, rails-frontend, and rails-access routers, which select rich-models variants. Select the test command from Testing: rspec uses bundle exec rspec; minitest uses bin/rails test. Do not follow a later example that contradicts the profile. This workflow is optional and never installs or changes project files unless it explicitly asks for confirmation.

## User Input

The user's request is whatever they wrote in the message that invoked this skill.

You **MUST** consider it before proceeding. If they gave none, continue without it.

## Outline

1. **Locate feature directory**: Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root. Parse JSON for FEATURE_DIR and FEATURE_SPEC. For single quotes in args, use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible).

2. **Validate spec exists**: Check that FEATURE_DIR/spec.md exists. If not, abort and instruct user to run `sdd-change-specify` first.

3. **Load context**:
   - **REQUIRED**: Read FEATURE_DIR/spec.md (the change spec)
   - **IF EXISTS**: Read `.specify/memory/constitution.md` to respect project principles
   - **IF EXISTS**: Read `.specify/memory/lessons-learned.md` — filter to entries tagged `[phase:implement]` or `[phase:all]`

4. **Load task template**: Read `.specify/templates/change-tasks-template.md` for the required flat format.

5. **Generate tasks** from the change spec:

   Extract from the spec:
   - The Problem and Proposed Change (what needs to happen)
   - The Acceptance Criteria (what must be verified)
   - The Files Likely Affected (where to make changes)

   Generate tasks in this order:
   1. **Migration/schema tasks** (if database changes needed)
   2. **Implementation tasks** (one per file or logical unit of change)
   3. **Test tasks** (write or update specs for changed behavior)
   4. **Validation task** (always last): use the profile-selected test command — `bundle exec rspec`
      for `Testing: rspec`, `bin/rails test` for `Testing: minitest` — then run the app's selected
      lint command. Never add a framework migration task merely to satisfy this workflow.

   Task format rules:
   - Format: `- [ ] T001 Description with exact file path`
   - Sequential numbering: T001, T002, T003...
   - No `[P]` markers (tasks are always sequential)
   - No `[US#]` markers (no user stories in the lightweight pipeline)
   - Include exact file paths in every task description
   - **Minimum 3, maximum 8 tasks**

   If the change requires more than 8 tasks, warn the user: "This change may need the full `sdd-tasks` pipeline for proper phase-based task organization." Wait for confirmation.

6. **Write tasks.md**: Write the generated task list to FEATURE_DIR/tasks.md using the change-tasks-template structure.

7. **Report**:
   - Output the tasks file path and total task count
   - Suggest next step: `sdd-change-implement`
