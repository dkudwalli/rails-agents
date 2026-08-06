# Your First SDD Feature

Spec Driven Development (SDD) is an optional Rails Engineer workflow: describe the outcome first, review the design artifacts, then implement and validate against the specification.

## Before you begin

1. Install Rails Engineer and run `rails-onboard` in the target application.
2. Select `Workflow: sdd` in its Rails Engineer Profile. If the profile selects `Workflow: conventional`, use the application's ordinary planning and delivery process instead.
3. Ask the assistant to use `sdd-init` once. It copies the Spec-Kit seed into the application's `.specify/` directory without overwriting `.specify/memory/`.

The SDD skills read the profile before working. They use the selected architecture, testing, CSS, frontend, authorization, database, and runtime choices; they do not convert an application to a different stack.

## Full workflow

Ask the assistant to use each skill in order. In a host that exposes user-invocable skills as slash commands, use the skill name there; otherwise state the requested skill in your message.

| Skill | Purpose |
|---|---|
| `sdd-specify` | Turn a feature request into `spec.md` and a requirements checklist |
| `sdd-clarify` | Optionally ask targeted questions for underspecified decisions |
| `sdd-spec-review` | Optionally challenge the specification for security, scale, edge cases, and compliance |
| `sdd-checklist` | Optionally create a domain-specific requirements-quality checklist |
| `sdd-plan` | Produce a technical plan and supporting research, data-model, and contract artifacts |
| `sdd-tasks` | Create a dependency-ordered `tasks.md` organized for execution |
| `sdd-analyze` | Optionally inspect spec, plan, and tasks for ambiguity, duplication, and coverage gaps |
| `sdd-implement` | Execute the approved task plan with the profile-selected conventions and test command |
| `sdd-validate` | Compare the implementation with the promised requirements |

For example: “Use `sdd-specify` for users bookmarking articles for later.” Review the resulting user stories, requirements, acceptance scenarios, and deliberate choices before continuing to planning.

## Small changes

For a tightly scoped bug fix or small feature, use the lighter sequence:

1. `sdd-change-specify`
2. `sdd-change-tasks`
3. `sdd-change-implement`

It creates a short change specification and flat task list instead of the full design-artifact set. Choose it only when the change is clearly bounded; use the full flow when there are cross-cutting requirements or unresolved design decisions.

## Artifacts and review

Artifacts live under `specs/<branch-name>/`. Depending on the chosen stages, that directory contains:

```text
spec.md
plan.md
tasks.md
research.md
data-model.md
contracts/routes.md
checklists/requirements.md
validation-report.md
```

These are ordinary Markdown files. Edit them whenever the team makes a better decision, then ask the next SDD skill to use the revised artifact. Review the specification before planning, the data model and contracts before tasks, and the validation report before merging.

## Tips

- Use `sdd-constitution` when the project needs to create or update its shared architectural principles.
- State requirements in observable terms; acceptance scenarios catch ambiguity sooner than implementation does.
- Keep the Rails Engineer Profile current. Rerun `rails-onboard` to revise only its marked section if the application's deliberately chosen stack changes.
- Do not use SDD as permission to change architecture or dependencies without recording that choice in the profile and reviewing it.
