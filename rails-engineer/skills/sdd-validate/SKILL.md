---
name: sdd-validate
description: >-
  Validate that the codebase implements what the feature spec promises using a
  4-layer hybrid analysis — no code annotations required. Use after sdd-implement
  completes, to confirm the delivered code matches spec.md. WHEN NOT:
  Implementation isn't finished yet — use sdd-implement; checking artifact
  consistency before implementation — use sdd-analyze.
---

> **Profile routing:** Read AGENTS.md and its Rails Engineer Profile before continuing. If Workflow: conventional, stop this SDD workflow and use the project's conventional planning and delivery process. If Workflow: sdd, use every selected profile value: layered work uses layered routers and variants; rich-models work uses the stable rails-architecture, rails-models, rails-testing, rails-css, rails-frontend, and rails-access routers, which select rich-models variants. Select the test command from Testing: rspec uses bundle exec rspec; minitest uses bin/rails test. Do not follow a later example that contradicts the profile. This workflow is optional and never installs or changes project files unless it explicitly asks for confirmation.

## User Input

The user's request is whatever they wrote in the message that invoked this skill.

You **MUST** consider it before proceeding. If they gave none, continue without it.

## Goal

Verify that the codebase implements what the feature specification promises. This command runs AFTER `sdd-implement` to detect spec drift — requirements that are unimplemented, broken, or diverged from the spec.

Uses a **4-layer hybrid approach** :
1. **Structural scan** — Rails convention-based file existence checks
2. **Test coverage mapping** — framework-aware test paths and descriptions
3. **AI semantic analysis** — LLM-powered code search for uncovered requirements
4. **Acceptance test generation** — On-demand, user-approved

## Operating Constraints

**READ-ONLY for source code**: Do not modify implementation files. The only files this command may write are the validation report (in FEATURE_DIR) and optionally the spec header (to record validation status).

**Constitution Authority**: If `.specify/memory/constitution.md` exists, check whether any constitution principles are violated by the implementation.

## Execution Steps

### 1. Initialize Validation Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root once. Parse JSON for:
- `FEATURE_DIR`
- `FEATURE_SPEC`
- `TASKS`

If FEATURE_SPEC does not exist, abort: "Run `sdd-specify` first."
For single quotes in args, use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible).

### 2. Load Spec and Extract Requirements

Read FEATURE_SPEC and extract:
- **Functional Requirements**: All FR-### identifiers with their full text
- **Success Criteria**: All SC-### identifiers with their full text
- **Acceptance Criteria**: All Given/When/Then scenarios from user stories
- **Key Entities**: Entity names mentioned in the spec

Build an internal **requirements inventory** — a list of requirement IDs, their text, and the entity/domain they relate to.

Also load:
- **IF EXISTS**: `.specify/memory/constitution.md` for principle validation
- **IF EXISTS**: `.specify/memory/lessons-learned.md` — filter to `[phase:implement]` or `[phase:all]`
- **IF EXISTS**: FEATURE_DIR/tasks.md — to cross-reference completed tasks with requirements

### 3. Layer 1 — Structural Scan (Rails Conventions)

For each **Key Entity** in the spec, check file existence using Rails naming conventions:

| Spec mentions entity | Check for |
|---------------------|-----------|
| `User` | `app/models/user.rb`, plus the profile-selected test location (`spec/` or `test/`) |
| `User` (with CRUD) | `app/controllers/users_controller.rb`, plus a profile-selected request or integration test |
| `User` (with business logic) | a service/query for layered, or a rich model/concern for rich-models |
| `User` (with authorization) | a policy for `Authorization: pundit`, or scoped model/controller code for `scoped-model` |
| `User` (with background job) | `app/jobs/*user*_job.rb` |
| `User` (with email) | `app/mailers/*user*_mailer.rb` |

For each **Functional Requirement**, infer expected files from the verb + entity:
- "System MUST validate email" → look for `validates :email` in the entity's model
- "System MUST send confirmation email" → look for a mailer
- "System MUST process payment in background" → look for a job

Record results: **EXISTS** or **MISSING** for each expected file/pattern.

### 4. Layer 2 — Test Coverage Mapping

Run `.specify/scripts/bash/collect-test-descriptions.sh` from repo root to collect all test descriptions.

Use the test structure configured by the profile. If the collection script does not understand the
selected framework, inspect the selected `spec/` or `test/` files directly and note that in the
report.

For each requirement in the inventory:

1. **Requirement marker match** (exact): Check for an explicit `FR-001` marker or matching
   documented scenario. If found, this is a definitive match.

2. **Description keyword match** (fuzzy): Extract key terms from the requirement text and match
   against test names, paths, and descriptions. Use these heuristics:
   - Entity name appears in test path or description
   - Action verb appears in test description (validate, create, send, process, etc.)
   - Requirement-specific terms appear (e.g., "email format", "password reset", "session timeout")

3. **For each matched test**: Note whether it exists (coverage) and whether it passes (correctness).
   If running tests is appropriate, use `bundle exec rspec <matched_file>` for `Testing: rspec` or
   `bin/rails test <matched_file>` for `Testing: minitest`.

Record results per requirement: **Test match (pass)**, **Test match (fail)**, or **No test match**.

### 5. Layer 3 — AI Semantic Analysis

For each requirement **not covered** by layers 1-2 (status is still "uncovered"):

Search the codebase for implementing code:
- Use Grep to search for requirement-specific terms across `app/` and `lib/`
- Read candidate files and assess whether they implement the requirement
- Consider indirect implementations (e.g., a concern that provides the behavior, a gem that handles it)

For each requirement, assess:
- **LIKELY COVERED**: Found code that clearly implements the requirement, but no direct test
- **PARTIALLY COVERED**: Found related code, but implementation appears incomplete
- **NOT COVERED**: No implementation evidence found

Record evidence: file paths, method names, and a brief explanation of why the match was made.

### 6. Layer 4 — Acceptance Test Generation (User-Approved)

If any requirements remain **NOT COVERED** or **LIKELY COVERED** after layers 1-3:

Present the user with an offer:

```
## Uncovered Requirements

[N] requirements have no direct test coverage:
- FR-003: [requirement text] — Status: LIKELY COVERED (AI-inferred)
- SC-001: [requirement text] — Status: NOT COVERED

Would you like me to generate acceptance tests from the spec's acceptance scenarios for these requirements?
This will create request, integration, or system tests in the profile-selected framework that
validate the behavior.

Reply: (1) Generate tests for all, (2) Pick specific ones, (3) Skip
```

If the user opts in:
- Generate request, integration, or system tests from the spec's Given/When/Then acceptance scenarios
- Add an explicit `FR-003` marker in the framework's normal test idiom
- Run the generated tests and report pass/fail
- **Do NOT modify existing test files** — only create new test files

If the user skips, proceed to report generation.

### 7. Constitution Compliance Check

If `.specify/memory/constitution.md` was loaded:

- Verify that implementation follows constitution principles (thin controllers, normalization-only
  callbacks, and the profile-selected domain boundary for side effects)
- Check for violations by scanning recently created/modified files
- Flag any violations as separate findings in the report (not requirement coverage, but compliance)

### 8. Generate Validation Report

Read `.specify/templates/validation-report-template.md` for the report structure.

Generate a validation report and write it to `FEATURE_DIR/validation-report.md` with:

- **Coverage summary**: Total requirements, covered count, percentage
- **Requirement status table**: One row per requirement with ID, text, evidence type, status, details
- **Coverage by layer**: How many requirements each layer resolved
- **Broken requirements**: Tests that exist but fail
- **Uncovered requirements**: No evidence found, with recommended actions
- **Constitution compliance**: Violations found (if any)

**Overall assessment**:
- **PASS**: All requirements covered (COVERED or test-pass status)
- **PARTIAL**: Some requirements only LIKELY COVERED or not covered, but no critical gaps
- **FAIL**: Critical functional requirements uncovered or broken

### 9. Update Spec Header (Optional)

If the user approves, update the spec's header metadata:

```markdown
**Implementation Status**: Validated [DATE]
**Coverage**: [X]/[Y] requirements ([Z]%)
**Branch**: `[branch-name]`
```

Ask: "Update spec header with validation results? (yes/no)"

Only modify the spec header — never change requirement content.

### 10. Provide Next Actions

Based on validation results:
- **If FAIL**: List critical gaps and recommend addressing them before merge
- **If PARTIAL**: List gaps and suggest `sdd-spec-review` to determine if the spec needs updating or the implementation needs extending
- **If PASS**: Confirm the implementation matches the spec; suggest proceeding to merge
- For LIKELY COVERED requirements: Recommend adding explicit tests to confirm
- Log any significant validation findings to `.specify/memory/lessons-learned.md` if they represent reusable learnings

## Validation Guidelines

### What This Command Checks
- Do the spec's functional requirements have corresponding implementation?
- Do existing tests cover the spec's acceptance criteria?
- Are tests passing for covered requirements?
- Does the implementation follow constitution principles?

### What This Command Does NOT Check
- Code quality (use `/code-review` for that)
- Security vulnerabilities (use `/security-audit` for that)
- Cross-artifact consistency (use `sdd-analyze` for that — it runs pre-implementation)
- Performance benchmarks (success criteria like "under 3 minutes" need manual/load testing)

### Relationship to Other Commands
- **After** `sdd-implement` — validates the implementation matches the spec
- **Complements** `sdd-analyze` — analyze checks artifacts pre-implementation; validate checks code post-implementation
- **Feeds into** `sdd-spec-review` — if gaps are found, spec-review can determine if the spec or the code needs updating

Context for validation focus: the user's request from the invoking message
