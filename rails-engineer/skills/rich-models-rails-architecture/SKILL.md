---
name: rich-models-rails-architecture
description: >-
  Decides where Rails code belongs in an application whose Rails Engineer Profile selects rich-models.
  Use before adding a controller action, model behavior, concern, state record, or domain object, or
  when a request suggests a service, query, form, or another application layer. WHEN NOT: a focused
  implementation already has a selected specialist skill.
---

# Rich-model Rails architecture

Read the target application's `AGENTS.md` and its Rails Engineer Profile first. This guidance
applies only when `Architecture: rich-models`. A recorded deliberate divergence is authoritative:
preserve an established service layer, component system, or other approved pattern rather than
migrating it merely to match this skill.

## Placement decisions

Start with the nearest comparable code in the application. Prefer one named domain concept and the
ordinary Rails artifact that already owns it over creating a new technical layer.

| The responsibility is primarily… | Place it in… | Then read… |
|---|---|---|
| HTTP, parameters, resource lookup, or response selection | a CRUD controller action | `crud-patterns` and the controllers convention reference |
| A domain verb, transaction, association, validation, or scope | the rich Active Record model | `rich-models-model-patterns` |
| One cohesive feature of a model, including its associations, scopes, predicates, and verbs | a namespaced model concern such as `Card::Closeable` | `concern-patterns` |
| A state, relationship, or action needing history, ownership, or its own endpoint | a record and resource such as `Closure` | `state-records`, `crud-patterns`, and the controllers convention reference |
| Behaviour truly shared by two or more models | a shared concern under `app/models/concerns/` | `concern-patterns` |
| A parser, value object, generator, search object, or one-off multi-step domain concept | a plainly named object under `app/models/` | `rich-models-model-patterns` |

Keep a controller to finding the record, calling one domain method, and choosing the response. Model
methods and concerns own the business behaviour they expose. When a proposed custom action is a
state change, name the noun it creates or destroys and model it as a resource before adding a verb
endpoint.

## Avoid category layers by default

Do not create `app/services`, `app/queries`, `app/forms`, `app/presenters`, or a similar category
directory as the default response to complexity. A plain object is allowed when it is a clear domain
concept, but it belongs with the domain in `app/models/`, not in a parallel architectural layer.

Use a model-namespaced concern when one model has a cohesive feature; promote it to a shared concern
only after a second model needs it. Prefer a state record over a boolean or timestamp when the state
needs to answer who or when, participate in queries, or be addressed as a resource.

For the full house rules and cited examples, read `37signals-conventions`, especially its models and
controllers references. Read `behavioral-guidelines` before introducing an abstraction: the right
placement can still be no new artifact.
