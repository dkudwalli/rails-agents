---
name: pr-artifact
argument-hint: <pr-url|pr-number|branch|diff-file|summary>
description: Creates one polished, self-contained HTML artifact that explains a pull request or code change for reviewers, maintainers, product partners, and stakeholders.
user-invocable: true
---

# Presenting Pull Requests

Create one unique, self-contained HTML artifact that helps the intended audience understand what changed, why it changed, how the change works, what is affected, how it was validated, and what risks or questions remain.

## Input

The PR or change source is whatever the user gave in the invoking message.

Accept any of these input forms:

* PR URL.
* PR number.
* Branch name, commit range, or comparison ref.
* Local diff or patch file.
* Markdown summary, release note, review notes, or implementation notes.
* Empty input, if the current repository and branch can provide enough context.

If they gave no source, first try to infer the change from the current git repository:

* Identify the current branch.
* Compare it against the repository's default branch when that is locally available.
* If no reliable comparison base exists, ask the user for a PR URL, PR number, branch, commit range, or diff file and stop.

If the source references network-only PR metadata and network access is unavailable, use local git information when possible and clearly mark unavailable metadata under `Open questions`.

## Output Requirement

Create a single `.html` file inside the `artifacts/` directory in the current working directory.

If `artifacts/` does not exist, create it.

The file must be fully self-contained:

* Include all CSS in a `<style>` tag.
* Include all JavaScript in a `<script>` tag.
* Do not depend on external CDNs, fonts, images, packages, analytics, or network requests.
* Use semantic HTML and accessible markup.
* Work by opening the file directly in a browser.

Name the file using a short slug derived from the PR title, branch, or change theme, for example:

```text
artifacts/pr-artifact-[slug].html
```

If no clear title exists, use:

```text
artifacts/pr-artifact.html
```

Do not overwrite an existing unrelated artifact unless the user explicitly asks. If the target filename exists, choose a clear variant such as `artifacts/pr-artifact-[slug]-v2.html`.

## Core Principles

* Treat the PR, diff, commits, and source notes as authoritative.
* Explain the change at the right altitude for reviewers and stakeholders.
* Preserve technical accuracy while translating dense implementation details into plain language.
* Make the review surface obvious: affected areas, behavior changes, validation, risk, rollout, and open questions.
* Separate verified facts from inferred implications.
* Make missing details visible instead of filling gaps with confident guesses.
* The artifact should feel intentionally designed, not templated.
* Avoid generic dashboard filler, decorative-only graphics, excessive cards, repeated section layouts, and one-note color palettes.

## Source Gathering

Gather only the context needed to explain the PR accurately.

Prefer local repository evidence when available:

* PR title, description, labels, author, review status, and linked issue if available.
* Commit list and commit messages.
* Changed files and file status.
* Diff summary, additions, deletions, renames, and moved files.
* Tests added, removed, or changed.
* Docs, migrations, configuration, API, schema, or dependency changes.
* CI, test, or validation output if available locally or included in the PR notes.

Useful local commands when applicable:

```bash
git status --short
git branch --show-current
git diff --stat
git diff --name-status
git log --oneline --decorate --max-count=20
```

For PR URLs or numbers, use available local tooling such as `gh` only when appropriate for the environment and user permissions. Do not require network access to create the artifact if local diff context is sufficient.

## Change Type Detection

Classify the PR as one or more of these types:

* Product feature
* Bug fix
* Refactor
* Performance
* Security or privacy
* Infrastructure / CI
* Dependency update
* Data / schema / migration
* Documentation
* Design / frontend UI
* API / integration
* Test-only change
* Other

Use the classification to choose the artifact structure, visual models, review focus, and level of detail. Label the classification only if it helps the reader.

## Source Parsing

Before writing HTML, identify and separate:

* PR title, branch, author, issue link, and current status when available.
* One-sentence change summary.
* User, business, technical, operational, or maintenance motivation.
* Explicit behavior changes.
* Affected surfaces, packages, services, routes, commands, APIs, schemas, configuration, and docs.
* Implementation approach and important design choices.
* Before and after behavior.
* Changed-file groups and ownership boundaries.
* Test coverage, CI status, manual validation, and unvalidated areas.
* Rollout, migration, release, rollback, or compatibility notes.
* Risks, tradeoffs, reviewer focus areas, and open questions.
* Reasonable inferences that should be labeled as `Inferred`.
* Missing information that belongs in `Open questions`.

## Required Understanding Goals

Every artifact must make these ideas easy to understand, using section names that fit the actual PR:

1. **What changed**

   * PR or change title
   * One-sentence summary
   * Change type
   * Primary files, modules, or product surfaces affected

2. **Why it changed**

   * Problem, user need, bug, cleanup goal, operational need, or linked initiative
   * Expected impact or value

3. **Before and after**

   * Previous behavior or structure
   * New behavior or structure
   * Compatibility, migration, or user-visible implications

4. **Implementation walkthrough**

   * Major workstreams or file groups
   * Key technical decisions
   * Data flow, control flow, UI flow, API flow, or dependency flow when relevant

5. **Review surface**

   * Files or areas reviewers should inspect closely
   * Risk level and why
   * Security, privacy, performance, accessibility, compatibility, or operational concerns when relevant

6. **Validation**

   * Tests added or changed
   * CI status or commands run, if available
   * Manual verification steps, if available
   * Important gaps or untested paths

7. **Release or rollout**

   * Deployment notes, feature flags, migrations, rollback, docs, comms, or monitoring
   * State clearly if the PR does not specify release or rollout details

8. **Open questions**

   * Missing PR metadata
   * Product, design, engineering, QA, security, release, analytics, or operational questions

If a required understanding goal has no source material, keep an appropriate section and clearly state that the PR does not specify it. Do not remove required understanding goals.

## Section Adaptation Guidance

Use change-specific sections when they improve comprehension:

* Product feature: user journey, UI states, affected workflows, launch and adoption signals.
* Bug fix: reproduction, root cause, fix path, regression tests, affected versions.
* Refactor: old structure, new structure, behavior preservation, blast radius, test confidence.
* Performance: bottleneck, changed path, benchmark results, expected impact, regression guardrails.
* Security or privacy: affected assets, trust boundaries, mitigations, residual risk, disclosure constraints.
* Infrastructure / CI: pipeline flow, environment impact, failure modes, rollback.
* Dependency update: package impact, compatibility, lockfile changes, vulnerability or feature rationale.
* Data / schema / migration: schema diff, data movement, rollout stages, rollback, integrity checks.
* Documentation: audience, changed guidance, source of truth, follow-up doc gaps.
* Design / frontend UI: before/after UI, interaction states, responsive behavior, accessibility checks.
* API / integration: contract changes, request/response flow, compatibility, consumers.
* Test-only change: coverage map, scenarios added, confidence gained, remaining blind spots.

## Design Requirements

Use a modern, clean visual style:

* Responsive layout for desktop and mobile.
* Strong typography using system fonts only.
* Clear color palette defined in CSS variables.
* Cards, badges, callouts, and section anchors.
* A first viewport that immediately communicates the PR title, change type, risk level, and primary impact.
* Stable dimensions for diagrams, cards, controls, and fixed-format UI elements so text and hover/focus states do not shift the layout.
* No horizontal scrolling on mobile.
* At least one visual representation, such as:

  * changed-file impact map
  * before/after flow
  * architecture or dependency map
  * request/data/control-flow diagram
  * review risk board
  * validation matrix
  * rollout checklist
  * timeline of commits or phases
  * component ownership map

Choose the visual model that best explains the actual PR. Use multiple visuals only when they add clarity.

Use the change's domain to choose the visual language:

* File impact map for broad diffs.
* Before/after comparison for behavior changes and UI changes.
* System map or dependency graph for architecture and integration changes.
* Flow diagram for API, data, control, or user-flow changes.
* Validation matrix for test-heavy or safety-critical PRs.
* Risk board for uncertain, cross-cutting, or high-risk PRs.
* Rollout checklist for deploy-sensitive changes.

Use JavaScript only when it improves comprehension, such as:

* collapsible detail sections
* tabbed views for files, risks, or validation
* section navigation
* simple filtering by file group, change type, or risk level
* expand/collapse of large file lists

Do not add JavaScript for decoration alone.

## Accessibility and Standalone Requirements

* Use semantic landmarks such as `header`, `nav`, `main`, `section`, and `article`.
* Include meaningful headings, labels, visible focus states, and keyboard-accessible interactive controls.
* If tabs, filters, or custom controls are used, include appropriate ARIA roles and keyboard behavior.
* Use sufficient color contrast and do not rely on color alone to communicate meaning.
* Include all CSS in one `<style>` tag.
* Include all JavaScript in one `<script>` tag.
* Do not use external fonts, images, scripts, stylesheets, CDNs, analytics, package imports, or network requests.

## Content Rules

* Preserve the meaning of the PR, diff, commits, and source notes.
* Do not invent requirements, reviewers, test results, CI status, issue links, benchmarks, or rollout plans.
* When making reasonable inferences, label them as `Inferred`.
* When information is missing, show it under `Open questions` instead of pretending it exists.
* Use only validation results from the source or commands actually run unless clearly labeled as `Suggested validation`.
* Keep suggested validation conservative and tied to the changed surfaces.
* Do not claim a bug, security issue, regression, or performance impact exists unless supported by the source. If something is only a review concern, label it as `Review focus`.
* Include code references, filenames, commands, and APIs when they help reviewers understand the change.
* Avoid dumping large diffs. Summarize patterns and quote only small snippets when necessary.
* Keep final page copy concise enough to scan.

## Workflow

1. Resolve the input source.

   * Determine whether the given source is a PR URL, PR number, branch, commit range, diff file, summary, or absent.
   * Gather local git context when useful.
   * If required information is unavailable, continue with what can be verified and record gaps under `Open questions`.

2. Build a content model.

   * Classify the change type.
   * Extract explicit PR facts.
   * Group changed files by surface or responsibility.
   * List behavior changes, implementation decisions, validation evidence, risks, and rollout notes.
   * List inferred implications.
   * List missing information and open decisions.
   * Decide which required understanding goals need an explicit "not specified" note.

3. Choose the artifact structure.

   * Pick the most useful visual model for the PR.
   * Create a clear page rhythm: hero, anchored sections, change map, walkthrough, review focus, validation, rollout, questions.
   * Avoid decorative complexity that does not improve comprehension.

4. Create the HTML file.

   * Write clean HTML, CSS, and JavaScript in one file.
   * Ensure the page is readable without scrolling horizontally.
   * Include meaningful headings and accessible labels.
   * Make interactive sections useful even if JavaScript is disabled where practical, for example with `details`/`summary`.

5. Validate the artifact.

   * Confirm it contains no external dependencies.
   * Confirm all required understanding goals are present or intentionally marked as missing.
   * Confirm inferred content is labeled.
   * Confirm suggested validation is labeled when validation evidence is missing.
   * Confirm links are internal anchors only unless the PR source explicitly requires otherwise.
   * Confirm the page has no horizontal overflow risk from fixed-width elements.
   * Confirm the file opens as standalone HTML.

Use quick local checks where available, for example:

```bash
rg -n "<(link|script|img|iframe|source)|href=|src=|@import|http|cdn|fonts" artifacts/pr-artifact-[slug].html
rg -n "What changed|Before|After|Implementation|Review|Validation|Rollout|Open Questions" artifacts/pr-artifact-[slug].html
```

The first check may show the inline `<script>` tag and internal `href="#..."` anchors. Treat external URLs, external `src`, `@import`, CDN references, and font downloads as failures.

6. Final response.

   * Provide the created path relative to the current working directory, for example `artifacts/pr-artifact-[slug].html`.
   * Summarize the artifact in 2-4 bullets.
   * Mention the PR source used, for example PR URL, branch comparison, commit range, diff file, or summary.
   * Mention important assumptions or missing source details.
   * Mention validation performed, or say what could not be validated.
