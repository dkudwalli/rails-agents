---
name: review-artifact
argument-hint: <review-notes|diff-file|pr-url|branch|report-file>
description: Creates one polished, self-contained HTML artifact from review findings, audit notes, PR feedback, code review output, security review notes, design review notes, QA reports, or implementation assessments.
user-invocable: true
---

# Presenting Reviews

Create one unique, self-contained HTML artifact that helps the intended audience understand the review scope, findings, evidence, severity, impact, remediation path, verification needs, and remaining questions.

## Input

The review source is whatever the user gave in the invoking message.

Accept any of these input forms:

* Review notes, audit notes, or markdown report.
* Code review comments or PR feedback.
* PR URL or PR number.
* Branch name, commit range, comparison ref, diff file, or patch file.
* QA report, bug bash notes, security review notes, accessibility review notes, performance review notes, design critique, or architecture assessment.
* Empty input, if the current repository and branch can provide enough context for a code-oriented review artifact.

If they gave no source, first try to infer review context from the current git repository:

* Identify the current branch.
* Compare it against the repository's default branch when that is locally available.
* Inspect local review-related files if clearly named, such as `review.md`, `audit.md`, `findings.md`, or `report.md`.
* If no reliable review source exists, ask the user for review notes, a report file, PR URL, branch, commit range, or diff file and stop.

If the source references network-only review or PR metadata and network access is unavailable, use local information when possible and clearly mark unavailable metadata under `Open questions`.

## Output Requirement

Create a single `.html` file inside the `artifacts/` directory in the current working directory.

If `artifacts/` does not exist, create it.

The file must be fully self-contained:

* Include all CSS in a `<style>` tag.
* Include all JavaScript in a `<script>` tag.
* Do not depend on external CDNs, fonts, images, packages, analytics, or network requests.
* Use semantic HTML and accessible markup.
* Work by opening the file directly in a browser.

Name the file using a short slug derived from the review subject, PR title, branch, or report title, for example:

```text
artifacts/review-artifact-[slug].html
```

If no clear title exists, use:

```text
artifacts/review-artifact.html
```

Do not overwrite an existing unrelated artifact unless the user explicitly asks. If the target filename exists, choose a clear variant such as `artifacts/review-artifact-[slug]-v2.html`.

## Core Principles

* Treat the review source, diff, report, comments, and evidence as authoritative.
* Put findings first, ordered by severity and practical impact.
* Separate confirmed findings from suspected risks, review focus areas, and suggested improvements.
* Make each finding actionable: what is wrong, where it appears, why it matters, and how to verify the fix.
* Preserve nuance. Do not inflate minor issues into blockers or downplay high-risk evidence.
* Make missing details visible instead of filling gaps with confident guesses.
* The artifact should feel intentionally designed, not templated.
* Avoid generic dashboard filler, decorative-only graphics, excessive cards, repeated section layouts, and one-note color palettes.

## Source Gathering

Gather only the context needed to present the review accurately.

Prefer local repository evidence when available:

* Review notes, report files, findings, comments, and reviewer summaries.
* Changed files, file status, and diff summary.
* Relevant code snippets, logs, screenshots references, test output, benchmark output, or reproduction steps included in the source.
* Existing tests, documentation, configuration, migrations, schemas, dependencies, or public interfaces affected by findings.
* CI, test, lint, audit, or validation output if available locally or included in the review source.

Useful local commands when applicable:

```bash
git status --short
git branch --show-current
git diff --stat
git diff --name-status
git log --oneline --decorate --max-count=20
rg -n "TODO|FIXME|SECURITY|audit|review|finding|risk|regression|failing|failure" .
```

For PR URLs or numbers, use available local tooling such as `gh` only when appropriate for the environment and user permissions. Do not require network access to create the artifact if local review or diff context is sufficient.

## Review Type Detection

Classify the review as one or more of these types:

* Code review
* Security / privacy review
* Accessibility review
* Performance review
* QA / test review
* Design / UX review
* Architecture review
* Reliability / operations review
* Data / migration review
* Dependency / supply-chain review
* Documentation review
* Compliance / policy review
* Other

Use the classification to choose the artifact structure, severity model, visual models, and level of detail. Label the classification only if it helps the reader.

## Source Parsing

Before writing HTML, identify and separate:

* Review subject, source, scope, reviewer, date, status, and audience when available.
* One-sentence review summary.
* Explicit findings and their evidence.
* Severity, confidence, impact, likelihood, and affected users or systems when stated.
* File paths, line references, modules, screens, APIs, workflows, environments, or artifacts involved.
* Reproduction steps, failure modes, logs, screenshots, benchmark data, or test output when available.
* Root cause or likely cause when supported by evidence.
* Recommended remediation and owner when stated.
* Verification steps, tests to add, retest plan, or acceptance criteria.
* Non-issues, accepted risks, deferrals, and constraints.
* Reasonable inferences that should be labeled as `Inferred`.
* Suspected but unconfirmed concerns that should be labeled as `Needs confirmation`.
* Missing information that belongs in `Open questions`.

## Severity and Evidence Rules

Use the source's severity labels if they exist. If the source does not define severity, infer a conservative severity and label it as `Inferred severity`.

Default severity levels:

* Critical: likely data loss, security exposure, severe outage, irreversible migration failure, or release-blocking user impact.
* High: important correctness, security, reliability, accessibility, performance, or compatibility issue with plausible user or business impact.
* Medium: meaningful defect, maintainability risk, confusing UX, incomplete validation, or rollout risk that should be addressed soon.
* Low: minor issue, polish, documentation gap, small maintainability concern, or optional improvement.
* Informational: context, observation, accepted tradeoff, or follow-up idea.

Every confirmed finding should include:

* Evidence.
* Affected area.
* Impact.
* Recommended fix or next step.
* Verification or retest guidance.

If any of those elements are missing, call that out explicitly instead of inventing it.

## Required Understanding Goals

Every artifact must make these ideas easy to understand, using section names that fit the actual review:

1. **Review summary**

   * Review subject
   * Review type
   * Scope and source
   * Overall status or risk posture, if supported by the source

2. **Findings**

   * Confirmed findings, ordered by severity
   * Evidence and affected areas
   * Impact and confidence

3. **Impact map**

   * Files, modules, screens, services, APIs, systems, users, or processes affected
   * Cross-cutting risks and ownership boundaries

4. **Remediation plan**

   * Recommended fixes or next steps
   * Priority order
   * Owners or responsible teams when stated
   * Dependencies and constraints

5. **Verification plan**

   * Tests, checks, audits, reproduction steps, or retest criteria
   * Commands run, CI results, or validation evidence if available
   * Gaps in validation

6. **Accepted risk and non-issues**

   * Tradeoffs, deferrals, non-blockers, false positives, or explicitly accepted risks
   * State clearly if the review does not specify any

7. **Open questions**

   * Missing evidence, unresolved product/design/engineering/security/QA/release questions, or unclear ownership

If a required understanding goal has no source material, keep an appropriate section and clearly state that the review does not specify it. Do not remove required understanding goals.

## Section Adaptation Guidance

Use review-specific sections when they improve comprehension:

* Code review: correctness findings, maintainability risks, API contracts, test coverage, file-level review focus.
* Security / privacy review: assets, trust boundaries, exploit path, mitigations, residual risk, disclosure constraints.
* Accessibility review: affected flows, WCAG category when available, assistive technology impact, retest steps.
* Performance review: bottleneck, benchmark evidence, user impact, regression threshold, profiling next steps.
* QA / test review: reproduction matrix, environment matrix, pass/fail map, regression coverage, release blockers.
* Design / UX review: user journey, interaction issues, visual hierarchy, responsive states, accessibility and copy notes.
* Architecture review: system boundaries, dependency map, tradeoffs, scaling risks, operability, migration path.
* Reliability / operations review: failure modes, alerting, runbooks, recovery path, blast radius, on-call impact.
* Data / migration review: data integrity, schema changes, backfill, rollback, monitoring, reconciliation checks.
* Dependency / supply-chain review: package risk, license, vulnerability, compatibility, lockfile and transitive impact.
* Documentation review: audience, accuracy gaps, missing procedures, stale references, source-of-truth conflicts.
* Compliance / policy review: control mapping, evidence gaps, residual risk, required approvals.

## Design Requirements

Use a modern, clean visual style:

* Responsive layout for desktop and mobile.
* Strong typography using system fonts only.
* Clear color palette defined in CSS variables.
* Cards, badges, callouts, and section anchors.
* A first viewport that immediately communicates the review subject, review type, finding count, highest severity, and overall posture when supported.
* Stable dimensions for diagrams, cards, controls, and fixed-format UI elements so text and hover/focus states do not shift the layout.
* No horizontal scrolling on mobile.
* At least one visual representation, such as:

  * severity board
  * finding triage table
  * affected-area heat map
  * risk matrix
  * remediation roadmap
  * verification checklist
  * evidence timeline
  * system or dependency map
  * user-flow issue map

Choose the visual model that best explains the actual review. Use multiple visuals only when they add clarity.

Use the review's domain to choose the visual language:

* Severity board for finding-heavy reviews.
* Risk matrix for high-uncertainty or security-sensitive reviews.
* Affected-area heat map for broad cross-file or cross-system reviews.
* Verification checklist for QA, accessibility, performance, and release-readiness reviews.
* System map or dependency graph for architecture, operations, and integration reviews.
* User-flow issue map for UX and accessibility reviews.
* Remediation roadmap for multi-step fix plans.

Use JavaScript only when it improves comprehension, such as:

* collapsible finding details
* tabbed views by severity, area, or review type
* section navigation
* simple filtering by severity, status, owner, area, or confidence
* expand/collapse of large evidence lists

Do not add JavaScript for decoration alone.

## Accessibility and Standalone Requirements

* Use semantic landmarks such as `header`, `nav`, `main`, `section`, and `article`.
* Include meaningful headings, labels, visible focus states, and keyboard-accessible interactive controls.
* If tabs, filters, or custom controls are used, include appropriate ARIA roles and keyboard behavior.
* Use sufficient color contrast and do not rely on color alone to communicate severity or status.
* Include all CSS in one `<style>` tag.
* Include all JavaScript in one `<script>` tag.
* Do not use external fonts, images, scripts, stylesheets, CDNs, analytics, package imports, or network requests.

## Content Rules

* Preserve the meaning of the review source, diff, comments, report, and evidence.
* Do not invent findings, severity, owners, fixes, test results, CI status, benchmarks, exploitability, compliance status, or approvals.
* When making reasonable inferences, label them as `Inferred`.
* When severity is inferred, label it as `Inferred severity`.
* When a concern is plausible but unconfirmed, label it as `Needs confirmation`.
* When information is missing, show it under `Open questions` instead of pretending it exists.
* Use only validation results from the source or commands actually run unless clearly labeled as `Suggested validation`.
* Keep suggested validation conservative and tied to the affected areas.
* Include file paths, line references, commands, APIs, routes, screens, or systems when they help the audience act on a finding.
* Avoid dumping large diffs, logs, or reports. Summarize patterns and quote only small snippets when necessary.
* Keep final page copy concise enough to scan.

## Workflow

1. Resolve the input source.

   * Determine whether the given source is review notes, a report file, PR URL, PR number, branch, commit range, diff file, summary, or absent.
   * Gather local review and git context when useful.
   * If required information is unavailable, continue with what can be verified and record gaps under `Open questions`.

2. Build a content model.

   * Classify the review type.
   * Extract explicit review facts.
   * Normalize findings by severity, confidence, affected area, and status.
   * Group affected files, systems, screens, workflows, or teams by responsibility.
   * List evidence, impact, remediation, verification, accepted risks, and non-issues.
   * List inferred implications and suspected concerns.
   * List missing information and open decisions.
   * Decide which required understanding goals need an explicit "not specified" note.

3. Choose the artifact structure.

   * Pick the most useful visual model for the review.
   * Create a clear page rhythm: hero, anchored sections, severity overview, findings, impact map, remediation, verification, accepted risk, questions.
   * Avoid decorative complexity that does not improve comprehension.

4. Create the HTML file.

   * Write clean HTML, CSS, and JavaScript in one file.
   * Ensure the page is readable without scrolling horizontally.
   * Include meaningful headings and accessible labels.
   * Make interactive sections useful even if JavaScript is disabled where practical, for example with `details`/`summary`.

5. Validate the artifact.

   * Confirm it contains no external dependencies.
   * Confirm all required understanding goals are present or intentionally marked as missing.
   * Confirm inferred content, inferred severity, and unconfirmed concerns are labeled.
   * Confirm suggested validation is labeled when validation evidence is missing.
   * Confirm links are internal anchors only unless the review source explicitly requires otherwise.
   * Confirm the page has no horizontal overflow risk from fixed-width elements.
   * Confirm the file opens as standalone HTML.

Use quick local checks where available, for example:

```bash
rg -n "<(link|script|img|iframe|source)|href=|src=|@import|http|cdn|fonts" artifacts/review-artifact-[slug].html
rg -n "Review summary|Findings|Impact|Remediation|Verification|Accepted risk|Open Questions" artifacts/review-artifact-[slug].html
```

The first check may show the inline `<script>` tag and internal `href="#..."` anchors. Treat external URLs, external `src`, `@import`, CDN references, and font downloads as failures.

6. Final response.

   * Provide the created path relative to the current working directory, for example `artifacts/review-artifact-[slug].html`.
   * Summarize the artifact in 2-4 bullets.
   * Mention the review source used, for example report file, review notes, PR URL, branch comparison, commit range, diff file, or summary.
   * Mention important assumptions or missing source details.
   * Mention validation performed, or say what could not be validated.
