---
name: specification-test
description: >-
  Decides which layer a piece of code belongs to by generating the test skeleton
  it would need and annotating which contexts belong at that layer. Use when code
  works but feels misplaced, when a controller or service spec has grown contexts
  that don't match its job, when deciding between controller / service / model
  for existing logic, or when user mentions misplaced logic, fat controller specs,
  slow specs, or heavy mocking. WHEN NOT: Choosing what test type to write for a
  layer you already decided on (use rails-architecture), deciding whether code is
  big enough to extract (use extraction-timing), or writing the actual tests
  (use rails-testing).
user-invocable: true
argument-hint: "[file path]"
---

You diagnose layer placement by looking at tests. Given a file, generate the spec skeleton it would need for
full coverage, then annotate each context with whether it belongs at that layer.

## The Principle

> If an object's specification describes features beyond the primary responsibility of its layer, those
> features belong in a lower layer.

You do not need to read the implementation carefully to apply this. You need to know what the object would
have to be *tested for*. A controller whose spec must set up three models and assert on a calculated total
is not a controller with a testing problem -- it's a controller holding domain logic.

## The Diagnostic

1. **Generate the skeleton.** Write the `describe`/`context` structure for full coverage. No `it` bodies, no
   implementations -- just the shape.
2. **Read what each context verifies.** Not what it's named. What would the assertion actually check?
3. **Annotate each one:**
   - **OK** -- belongs at this layer
   - **WARN** -- ambiguous, judgement call, or a known grey area
   - **MOVE** -- verifies something outside this layer's job; name the destination

Then compare against the *actual* spec file if one exists, and report the delta.

### Two generation rules

- **Skip declarative configuration.** Don't generate contexts for `belongs_to`, `enum`, or simple presence
  validations. Rails already guarantees these; contexts for them clutter the skeleton without informing the
  placement decision.
- **Authorization predicates are WARN by default.** A `can_edit?` or `accessible_to?` on a model is usually
  a policy in disguise. Mark it OK only if the project demonstrably has no policy layer.

## What Each Layer's Spec Should Verify

Mirrors the `Testing Strategy by Layer` table in the `rails-architecture` skill -- that table
says which test type a layer gets; this one says which *assertions* are legitimately its own.

| Layer | Spec should verify | Spec should NOT verify |
|-------|--------------------|------------------------|
| Controller | Authentication, authorization enforcement, status codes, redirects, param handling, response format | Business rules, calculations, state transitions, external service behavior |
| Service | Which collaborators were orchestrated, transaction boundaries, success/failure result shape, error handling | Domain validation rules, business calculations, HTTP concerns |
| Model | Validations, business rules, calculations, state transitions, scopes | HTTP concerns, notification delivery, external API calls |
| Query | Result correctness, edge cases, empty states, tenant isolation | Business decisions about the results, formatting |
| Policy | Every action for every role | How the decision is enforced, or what happens after |
| Presenter | Formatting output, nil handling | Data fetching, authorization, business logic |
| Component | Rendered markup, slots, variants, `render?` conditions | Data fetching, business decisions (pass them in) |

## Example: Controller

```ruby
describe "POST /orders" do
  context "when unauthenticated"                # OK   authentication
  context "when user cannot create orders"      # OK   authorization enforcement
  context "with invalid params"                 # OK   422 + re-render
  context "when the order is valid"             # OK   redirect + flash
  context "when discount exceeds 50%"           # MOVE domain rule -> Order model
  context "when inventory is insufficient"      # MOVE domain rule -> Order model
  context "when the payment gateway times out"  # MOVE orchestration -> Orders::CreateService
end
```

Four of seven contexts belong here. The other three are the extraction list.

**After extraction:**

```ruby
describe "POST /orders" do
  context "when unauthenticated"
  context "when user cannot create orders"
  context "with invalid params"
  context "when the order is valid"
end

describe Orders::CreateService do
  context "when the payment gateway times out"   # OK   orchestration failure
  context "when all steps succeed"               # OK   result shape
end

describe Order do
  context "when discount exceeds 50%"            # OK   business rule
  context "when inventory is insufficient"       # OK   business rule
end
```

## Example: Service

```ruby
describe Orders::CreateService do
  context "when the order saves"                 # OK   result shape
  context "when payment fails"                   # OK   error handling
  context "when the mailer raises"               # OK   orchestration failure
  context "when discount exceeds 50%"            # MOVE business rule -> Order
  context "when total is below the minimum"      # MOVE business rule -> Order
end
```

A service that tests business rules is a symptom of an anemic model. The rule doesn't move *up* to the
service because the service happens to call it -- it belongs on the record that owns the data.

## Example: Model

```ruby
describe Order do
  context "validations"                          # OK   (but skip the declarative ones)
  describe "#total"                              # OK   domain calculation
  describe "#apply_discount"                     # OK   domain rule
  context "when confirmation is sent"            # MOVE notification -> service
  context "when synced to the warehouse"         # MOVE external API -> service
  describe "#editable_by?"                       # WARN policy candidate
end
```

The last three are the usual callback symptoms: if the model spec has to assert an email was delivered,
there's an operation callback in the model. Score it with `/extraction-timing` -- it will land at 1 or 2.

## Why This Matters: Test Cost

The argument for pushing logic down is not purity. It's that the same rule costs more to test the higher it
sits, and you pay that cost on every future change.

| Test type | Speed | Setup complexity | Brittleness |
|-----------|-------|------------------|-------------|
| Model / unit | Fast | Low | Low |
| Service | Medium | Medium | Medium |
| Request | Slow | High | High |
| System | Slowest | Highest | Highest |

A discount rule tested in a request spec needs a signed-in user, a cart, params, and a route -- and breaks
when any of them change. The same rule on the model needs one object.

## Symptoms Worth Hunting

Signs in an existing spec that logic is sitting too high:

- Heavy mocking inside a model spec
- Long factory chains for what should be a unit test
- `update_columns` or `skip_callbacks` in setup (fighting the model to construct a state)
- A request spec asserting on a calculated value rather than a response
- Contexts named after business scenarios in a controller spec

## Output Format

Report in this order:

1. **Verdict line** -- one sentence: how many contexts belong here, how many should move.
2. **Annotated skeleton** -- the generated structure with OK / WARN / MOVE per context.
3. **Existing spec delta** -- if a spec file exists, what it covers that it shouldn't, and what's missing.
4. **Extraction list** -- each MOVE with its destination layer and a one-line reason.

Follow the reporting rules in the `behavioral-guidelines` skill -- especially: omit empty
sections, and never recommend deleting a duplicated test without showing the delegation test that replaces
it.

## Related

- **the `rails-architecture` skill** -- which layer owns what, and which test type each layer
  gets. Use it when you know the layer and need the shape; use this skill when the layer itself is in doubt.
- **the `extraction-timing` skill** -- the thresholds that say *when* something is big enough
  to extract. This skill says *where* it goes. They pair: a threshold fires, then the specification test
  picks the destination.
