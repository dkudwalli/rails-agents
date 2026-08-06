---
name: sdd-plan
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
---

> **Profile routing:** Read AGENTS.md and its Rails Engineer Profile before continuing. If Workflow: conventional, stop this SDD workflow and use the project's conventional planning and delivery process. If Workflow: sdd, use every selected profile value: layered work uses layered routers and variants; rich-models work uses the stable rails-architecture, rails-models, rails-testing, rails-css, rails-frontend, and rails-access routers, which select rich-models variants. Select the test command from Testing: rspec uses bundle exec rspec; minitest uses bin/rails test. Do not follow a later example that contradicts the profile. This workflow is optional and never installs or changes project files unless it explicitly asks for confirmation.

## User Input

The user's request is whatever they wrote in the message that invoked this skill.

You **MUST** consider it before proceeding. If they gave none, continue without it.

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. **IF EXISTS**: Read `.specify/memory/lessons-learned.md` — filter to entries tagged `[phase:plan]` or `[phase:all]` and note any architectural or design lessons relevant to the current feature's domain. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task
   - If `.specify/memory/lessons-learned.md` exists and contains entries tagged `[phase:plan]` or `[category:architecture]`: check if any past learning applies to current unknowns or technology choices — reference applicable lessons in research tasks rather than re-investigating from scratch

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - **Migration safety plan**: all migrations MUST be reversible, no mixed DDL and data manipulation in the same migration, `disable_ddl_transaction!` for concurrent index creation if needed, foreign key constraints with explicit `on_delete` behavior, migration order matching model dependency graph

2. **Define route contracts** → `/contracts/routes.md`:
   - Map feature resources to RESTful routes using Rails `resources`/`namespace` DSL
   - Document route helpers, HTTP methods, and controller#action mappings
   - Include any non-RESTful member/collection routes with justification

3. **Define additional interface contracts** (if project has external interfaces beyond routes) → `/contracts/`:
   - Document the contract format appropriate for the interface type
   - Skip if all interfaces are covered by route contracts

4. **Create Hotwire decision matrix** → included in plan.md:
   - Map each user-facing interaction to Turbo Drive / Turbo Frame / Turbo Stream / Stimulus
   - Default to Turbo Drive unless a specific interaction needs finer granularity
   - Document rationale for each choice

5. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
