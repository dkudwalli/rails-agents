---
name: behavioral-guidelines
description: >-
  Behavioral guidelines to reduce common LLM coding and reporting mistakes. Use
  when writing, reviewing, or refactoring code to avoid overcomplication, make
  surgical changes, surface assumptions, and define verifiable success criteria;
  and when producing a review, audit, or analysis report to keep findings concrete
  and drop filler.
  WHEN NOT: Picking which layer or pattern code belongs in (use rails-architecture
  or specification-test) or looking up an extraction threshold (use
  extraction-timing) -- those two answer "where" and "how big"; this skill answers
  whether the code should exist at all, and they route here for it.
---

# Guidelines

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Reporting Rules

**Applies to any review, audit, or analysis output.**

### Omit empty sections

If a check found nothing, delete the section. Don't emit "No violations found" or "✅ All clear" for every
heading -- a report padded with clean sections buries the findings that matter and reads as thorough when
it isn't.

### Drop vague recommendations entirely

Every recommendation must be actionable without further interpretation:

- "Add a CI guard" without the rule pattern → drop it
- "Introduce a base class" without naming what machinery would be hoisted into it → drop it
- "Improve test coverage" without naming the untested paths → drop it

A vague item dilutes the concrete ones around it. If the analysis can't get specific -- data missing, scope
too large -- say that explicitly instead of gesturing at the problem.

### Concrete evidence over adjectives

Cite `file:line`. Give counts and percentages. "Mixed parameter style (kwargs 64%, positional 36%)" beats
"inconsistent parameter conventions."

### State rules directly, without attribution

Don't write "per Fowler's anemic domain model," "the Avdi smell," or "Sandi Metz says." The reader doesn't
know who those are, and the name doesn't make the rule truer. State what's wrong and why. If a source is
genuinely load-bearing, put it in a short "Read more" list at the end -- and omit that section entirely
when you're just applying general principles.

Explain a term the first time it appears rather than assuming it: "specification test" is fine to use, once
you've said what it means.

### Two rules for reviewing tests

- **Never recommend testing private methods via `send`.** If a private method needs isolated testing, that's
  a signal the class should be decomposed. Say that instead.
- **Never recommend deleting a duplicated test without showing its replacement.** If lower-layer coverage
  makes a higher-layer test redundant, supply the delegation test that keeps the boundary covered -- one
  that mocks the lower layer and asserts it was invoked.
