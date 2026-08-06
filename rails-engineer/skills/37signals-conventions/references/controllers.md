---
paths:
  - "app/controllers/**/*.rb"
  - "test/controllers/**/*.rb"
  - "config/routes.rb"
---

# Controller Conventions (37signals)

- Name states and relationships as **nouns**, then expose them as resources. When you want a verb
  endpoint, name the noun the verb creates or destroys: `Closure`, `Publication`, `Watch`, `Pin`,
  `Access`, `Ban`
- State changes become singular resources: `resource :closure` (POST closes, DELETE reopens) — not
  `post :close`
- Stay within the 7 REST actions. Custom routes are for integrations, protocol endpoints, and
  compatibility redirects only — name the exception when you add one
- An action does at most three things: find the record, call one domain method, select a response.
  Branch in a private method, not in the action
- **Authorization is scoping, not a policy object.** Scope record lookups through the current actor
  so an inaccessible record is never found and `find` raises → 404. There is no `authorize!` call
- Beyond visibility, gate on a model predicate:
  `head :forbidden unless Current.user.can_administer_card?(@card)`
- Use `<Parent>Scoped` concerns per routing nesting level (`CardScoped`) for lookup plus shared rendering
- `ApplicationController` is a list of concerns, not a home for method bodies
- Put `only:`/`except:` on nearly every route so `rails routes` is a truthful inventory
- Nest routes only to express ownership; `scope module:` nests controllers without nesting URLs
- Use `direct` / `resolve` to teach the router about models rather than scattering path conditionals
- Instance variables are the contract with the view; leave empty actions empty
- Use `fresh_when` / `stale?` for HTTP caching, and `respond_to` with `format.turbo_stream` and `format.html`

> Fizzy profile only: `params.expect` for required parameter shapes, and scoping every query through
> `Current.account`. Campfire and Writebook use `params.require(...).permit(...)` and have no account
> layer. `params.expect` is an edge-Rails feature — verify it exists in your Rails release.

See [`04-controllers-routing.md`](../../../docs/37signals-playbook/04-controllers-routing.md).
