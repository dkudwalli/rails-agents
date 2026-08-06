---
name: layered-rails-architecture
description: >-
  Guides modern Rails 8 code architecture decisions and patterns. Use when
  deciding where to put code, choosing between patterns (service objects vs
  concerns vs query objects), designing feature architecture, refactoring
  for better organization, or when user mentions architecture, code
  organization, design patterns, or layered design. WHEN NOT: Implementing
  specific patterns (use specialist agents like service-agent or query-agent),
  writing tests, or debugging runtime errors.
model: sonnet
effort: high
---

# Modern Rails 8 Architecture Patterns

## Architecture Decision Tree

```
Where should this code go?
|
+- View/display formatting?       -> Presenter (@presenter-agent)
+- Complex business logic?        -> Service Object (@service-agent)
+- Complex database query?        -> Query Object (@query-agent)
+- Shared behavior across models? -> Concern (/rails-concern skill)
+- Authorization logic?           -> Policy (@policy-agent)
+- Reusable UI with logic?        -> ViewComponent (@viewcomponent-agent)
+- Async/background work?         -> Job (@job-agent, /solid-queue-setup skill)
+- Complex form (multi-model)?    -> Form Object (@form-agent)
+- Transactional email?           -> Mailer (@mailer-agent)
+- Real-time/WebSocket?           -> Channel (/action-cable-patterns skill)
+- Data validation only?          -> Model (@model-agent)
+- HTTP request/response only?    -> Controller (@controller-agent)
+- Already written, feels wrong?  -> Diagnose placement (/specification-test skill)
```

## Layer Responsibilities

| Layer | Responsibility | Should NOT contain |
|-------|---------------|-------------------|
| **Controller** | HTTP, params, response | Business logic, queries |
| **Model** | Data, validations, relations | Display logic, HTTP |
| **Service** | Business logic, orchestration | HTTP, display logic |
| **Query** | Complex database queries | Business logic |
| **Presenter** | View formatting, badges | Business logic, queries |
| **Policy** | Authorization rules | Business logic |
| **Component** | Reusable UI encapsulation | Business logic |
| **Job** | Async processing | HTTP, display logic |
| **Form** | Complex form handling | Persistence logic |
| **Mailer** | Email composition | Business logic |
| **Channel** | WebSocket communication | Business logic |

### Decoding tier vocabulary

This pack names layers by Rails artifact (the table above). Most Rails architecture writing -- and tools like
the `layered-rails` plugin -- use four abstract tiers instead. Use this to translate; don't adopt the tier
names in our own guidance.

| Tier | Our artifacts |
|------|---------------|
| Presentation | Controllers, views, components, presenters, forms, mailers, channels |
| Application | Services, policies |
| Domain | Models, queries, concerns |
| Infrastructure | Active Record, API clients, jobs, storage |

The rule those tiers encode -- dependencies point downward, never up -- is already spelled out concretely as
the allowed and forbidden call graphs in `references/layer-interactions.md`.

## When NOT to Abstract

| Situation | Keep It Simple | Don't Create |
|-----------|----------------|--------------|
| Simple CRUD | Keep in controller | Service object |
| Used only once | Inline the code | Abstraction |
| Simple query with 1-2 conditions | Model scope | Query object |
| Basic text formatting | Helper method | Presenter |
| Single model form | `form_with model:` | Form object |
| Simple partial without logic | Partial | ViewComponent |

Read the `behavioral-guidelines` skill § Simplicity First and apply it before this table. The table
answers "which abstraction"; those rules answer the question that comes first -- whether the code needs
to exist at all. An abstraction nobody asked for fails there before it ever reaches a row here.

## When TO Abstract

| Signal | Action |
|--------|--------|
| Same code repeated across the app | Extract to concern/service |
| Controller action carries business logic | Extract to service |
| Model has grown past persistence concerns | Extract concerns, services, query objects |
| Complex conditionals | Extract to policy/service |
| Query joins several tables or has conditional clauses | Extract to query object |
| Form spans multiple models | Extract to form object |

**The numbers live in one place.** This table names the *signals*; `/extraction-timing` owns the thresholds
that decide when each one fires (model size, controller action length, query complexity, callback scores,
churn and complexity). Don't restate a threshold here -- point at that skill.

## Core Patterns

### Skinny Controllers

```ruby
# GOOD: Thin controller delegates to service
class OrdersController < ApplicationController
  def create
    result = Orders::CreateService.call(user: current_user, params: order_params)
    if result.success?
      redirect_to result.data, notice: t(".success")
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end
end
```

### Result Objects for Services

All services return a consistent Result object, defined once on `ApplicationService`:

```ruby
Result = Data.define(:success, :data, :error, :code) do
  def success? = success
  def failure? = !success
end
```

`code` is a typed symbol callers branch on (`nil` on success). The base class that carries this and
the `success`/`failure` constructors is in the `service-patterns` skill; the code vocabulary and the
controller branching are in [error-handling.md](references/error-handling.md).

### Multi-Tenancy by Default

```ruby
# GOOD: Scoped through account
def index
  @events = current_account.events.recent
end
```

## Rails 8 Specific Features

| Feature | Purpose | Skill/Agent |
|---------|---------|-------------|
| Authentication | `has_secure_password` generator | /authentication-flow |
| Background Jobs | Solid Queue (database-backed) | /solid-queue-setup, @job-agent |
| Real-time | Action Cable + Solid Cable | /action-cable-patterns |
| Caching | Solid Cache (database-backed) | /caching-strategies |
| Assets | Propshaft + Import Maps | (built-in) |
| Deployment | Kamal 2 + Thruster | (built-in) |

## Testing Strategy by Layer

Each layer gets the test type that matches what it owns — unit specs for models, services, queries,
presenters and policies; request specs for controllers; system specs only for critical paths.
[`references/testing-strategy.md`](references/testing-strategy.md) has the pyramid, the coverage
targets, and the table of which skill holds each layer's worked specs.

## New Feature Checklist

1. **Model** - Define data structure (@migration-agent, @model-agent)
2. **Policy** - Add authorization rules (@policy-agent)
3. **Service** - Create for complex logic (@service-agent)
4. **Query** - Add for complex queries (@query-agent)
5. **Controller** - Keep it thin (@controller-agent)
6. **Presenter** - Format for display (@presenter-agent)
7. **Component** - Build reusable UI (@viewcomponent-agent)
8. **Mailer** - Add transactional emails (@mailer-agent)
9. **Job** - Add background processing (@job-agent)

## References

This skill decides *where* code goes. It does not carry the code — each layer's worked
implementations live in that layer's own skill, and this file must never grow a copy.

| Read | For |
|---|---|
| [layer-interactions.md](references/layer-interactions.md) | The full request walked through all eleven layers, plus the allowed and forbidden call graphs |
| [error-handling.md](references/error-handling.md) | Result objects, typed error codes, controller and API error branching |
| [testing-strategy.md](references/testing-strategy.md) | Test pyramid, coverage targets, and which skill holds each layer's specs |

Worked implementations by layer: `service-patterns`, `query-patterns`, `layered-model-patterns`,
`controller-patterns`, `policy-patterns`, `form-patterns`, `presenter-patterns`,
`viewcomponent-patterns`, `layered-job-patterns`, `layered-mailer-patterns`. The house rules those implementations
obey are in `layered-conventions`.
