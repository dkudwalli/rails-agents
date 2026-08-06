---
name: sdd-implement
description: >-
  Execute the implementation plan phase-by-phase using the architecture, tests,
  views, CSS, and access mechanisms recorded in AGENTS.md. Use after tasks.md
  exists (and sdd-analyze has passed, if used) to build the feature. WHEN NOT: No
  tasks.md exists yet — run sdd-plan/sdd-tasks first; a small change — use
  sdd-change-implement.
---

> **Profile routing:** Read AGENTS.md and its Rails Engineer Profile before continuing. If Workflow: conventional, stop this SDD workflow and use the project's conventional planning and delivery process. If Workflow: sdd, use every selected profile value: layered work uses layered routers and variants; rich-models work uses the stable rails-architecture, rails-models, rails-testing, rails-css, rails-frontend, and rails-access routers, which select rich-models variants. Select the test command from Testing: rspec uses bundle exec rspec; minitest uses bin/rails test. Do not follow a later example that contradicts the profile. This workflow is optional and never installs or changes project files unless it explicitly asks for confirmation.

## User Input

The user's request is whatever they wrote in the message that invoked this skill.

You **MUST** consider it before proceeding. If they gave none, continue without it.

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   - **IF EXISTS**: Read `.specify/memory/lessons-learned.md` for cross-feature learnings — filter to entries tagged `[phase:implement]` or `[phase:all]` and note any relevant to the current feature's tech stack or error-prone areas

4. **Project Setup Verification**:
   - **REQUIRED**: Verify `.gitignore` contains essential Ruby/Rails patterns:

   **Detection & Creation Logic**:
   - Check if the repository is a git repo:

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - If `.gitignore` exists: Verify it contains essential patterns, append missing critical patterns only
   - If `.gitignore` is missing: Create with full Rails pattern set

   **Required `.gitignore` Patterns (Rails)**:
   - **Ruby/Rails**: `.bundle/`, `log/`, `tmp/`, `storage/`, `*.gem`, `vendor/bundle/`, `db/*.sqlite3`, `db/*.sqlite3-*`, `public/assets/`
   - **Secrets**: `.env`, `.env.*`, `*.pem`, `*.key`, `config/master.key`, `config/credentials/*.key`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   - Check if Dockerfile* exists → create/verify `.dockerignore` with: `.git/`, `log/`, `tmp/`, `storage/`, `node_modules/`, `.bundle/`, `*.sqlite3`, `.env*`

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. Execute implementation using **fresh-context subagents** per task:

   The parent agent (you) acts as an **orchestrator**. Instead of executing all tasks inline (which causes context rot on long sessions), delegate each implementation task to a fresh subagent via the **Agent tool**, routed to the **specialist agent** that matches the task (see Specialist agent routing below). Each subagent gets a clean context window with only the information it needs.

   **Profile routing** — use the router before selecting a task implementation boundary:

   | Profile decision | Task guidance |
   |---|---|
   | `Architecture: layered` | Use `rails-architecture` and the selected layered specialist for services, queries, policies, forms, or components. |
   | `Architecture: rich-models` | Use `rails-architecture`, `rails-models`, and the matching `rich-models-*` variant; keep domain behavior in models or concerns. |
   | `Testing: rspec` | Write and run specs under `spec/` with `bundle exec rspec`. |
   | `Testing: minitest` | Write and run tests under `test/` with `bin/rails test`. |
   | `Views`, `CSS`, `Authorization` | Use `rails-frontend`, `rails-css`, and `rails-access`; do not create an unselected component, CSS, or policy layer. |

   - Choose work by the task's primary output and profile route. If a task spans boundaries, split it.
   - **TDD pairing**: write the selected-framework failing test, then implement the matching
     profile-selected behavior, and run that same framework to confirm RED → GREEN.

   This portable plugin ships skills, not host-specific agents. If the host supports subagents, give
   each one the selected profile and router guidance; otherwise execute inline in the same phase
   order. Never substitute a layered specialist for rich-models work.

   **Execution rules:**
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Direct execution (no subagent)**: Phase 1 (Setup) tasks and the final Polish phase — these are small config changes or CLI tool runs that don't benefit from subagent isolation
   - **Subagent execution**: All other phases (Foundational, User Stories) — spawn a fresh Agent per task, routed to the matching specialist via `subagent_type`
   - **Sequential tasks** (no `[P]` marker): Execute one subagent at a time, wait for completion before starting the next
   - **Parallel tasks** (`[P]` marker): Spawn multiple subagents concurrently using parallel Agent tool calls — only when tasks modify different files and have no dependencies on each other
   - **File-based coordination**: If two `[P]` tasks touch the same file, execute them sequentially despite the parallel marker
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **Validation checkpoints**: Verify each phase completion before proceeding

   **Subagent context composition** — assemble this for each task before spawning:
   1. **Constitution**: Read `.specify/memory/constitution.md` and include its full content (non-negotiable principles)
   2. **Plan summary**: Extract only the Technical Context, Project Structure, and Hotwire Decision Matrix sections from plan.md (not the full plan)
   3. **Relevant spec section**: If task has a `[US#]` label, include only that user story section from spec.md (story description, acceptance scenarios, edge cases). For tasks without a story label (Foundational phase), include the Functional Requirements and Key Entities sections
   4. **Data model**: If data-model.md exists, include entity definitions relevant to this task
   5. **Task description**: The exact task line from tasks.md (ID, markers, description, file path)
   6. **Lessons learned**: If `.specify/memory/lessons-learned.md` exists, include entries tagged `[phase:implement]` or `[phase:all]`
   7. **Phase progress**: A brief list of files created/modified by prior tasks in the current phase (so the subagent knows what already exists)

   **Subagent prompt template** (passed as the Agent tool's `prompt`, alongside the routed `subagent_type`):
   ```
   You are implementing a single task for a Rails application. Follow the constitution principles strictly.

   ## Constitution
   {constitution content}

   ## Technical Context
   {plan summary sections}

   ## Feature Context
   {relevant spec section}

   ## Data Model
   {data model if applicable}

   ## Your Task
   {task ID and full description with file path}

   ## Already Built This Phase
   {list of files created/modified by prior tasks}

   ## Lessons Learned
   {filtered lessons}

   ## Instructions
   - Implement ONLY this task — do not modify files outside its scope
   - Follow the selected Rails Engineer Profile and router; use services only for a layered profile
     and rich models or concerns for a rich-models profile
   - Write minimal, correct code that satisfies the task description
   - If the task includes writing tests, ensure they pass
   - Report what files you created or modified when done
   ```

   **Per-task verification** (parent runs after each subagent completes):
   - Run the application's configured linter on files the subagent created or modified
   - If the task involved tests, run `bundle exec rspec {test_file}` for `Testing: rspec` or
     `bin/rails test {test_file}` for `Testing: minitest`

   **Per-phase verification** (parent runs after all tasks in a phase complete):
   - Run `bundle exec rspec` for `Testing: rspec` or `bin/rails test` for `Testing: minitest` to
     catch regressions across the full suite
   - If system tests exist, use the selected framework's system-test command

   **Error handling for subagents**:
   - If a subagent fails or produces code that doesn't pass verification: retry **once** with the error output included in the subagent prompt as additional context
   - If the retry also fails: halt execution for that task, log the error to `.specify/memory/lessons-learned.md`, and report the failure to the user with context for manual resolution
   - For parallel `[P]` tasks: if one fails, continue with the others and report the failure separately

7. Implementation phase guide (what each phase typically involves):
   - **Setup (Phase 1, parent-executed)**: Initialize config initializers, routes, dependencies — execute these directly without subagents
   - **Foundational (Phase 2, subagent-executed)**: Run migrations, create models, and write tests
     in the selected framework; give each task the matching router guidance
   - **User Stories (Phase 3+, subagent-executed)**: Implement the profile-selected domain boundary,
     controllers, and views per user story with only that story's spec section
   - **Polish (Final phase, parent-executed)**: run the configured linter, `bin/brakeman --no-pager`
     when available, and the profile-selected full test command

8. Progress tracking and error handling (parent orchestrator responsibilities):
   - Report progress after each completed task (whether parent-executed or subagent-executed)
   - After each subagent completes: collect its result, verify the output, and update tasks.md — the parent owns all file tracking, not the subagent
   - Halt execution if any non-parallel task fails (after the retry attempt described in step 6)
   - For parallel tasks [P], continue with successful subagents, report failed ones separately
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file. This is always done by the parent, not by subagents.
   - **LESSONS CAPTURE (errors)**: When a significant implementation problem occurs (dependency conflict, unexpected framework behavior, workaround for a limitation, recurring test failure pattern), append a concise entry to `.specify/memory/lessons-learned.md` under the appropriate section using the entry format documented in that file. Only log problems useful for future features — skip routine debugging and typos. Create the file with its standard header if it does not exist.

9. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Report final status with summary of completed work

   **Lessons learned capture (completion)**:
   - Review the implementation session for noteworthy patterns, surprises, or insights
   - Present the user with a brief prompt:
     ```
     ## Lessons Learned

     Implementation complete. Any learnings worth recording for future features?

     Suggested based on this session:
     - [1-3 specific observations from the implementation]

     Reply: (1) Accept suggestions, (2) Add your own, (3) Skip
     ```
   - If the user provides input, append entries to `.specify/memory/lessons-learned.md`
   - If the user skips, proceed without writing
   - Create the file with its standard header if it does not exist

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `sdd-tasks` first to regenerate the task list.
