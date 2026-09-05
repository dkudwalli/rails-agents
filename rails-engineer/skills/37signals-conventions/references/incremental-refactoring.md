# Incremental refactoring toward rich models

Use this guide when a ChannelBay change touches a service that owns local domain behavior.

## New behavior

Start with the owning model and its resource boundary. Add a named domain method or a
model-namespaced concern when the behavior owns a coherent feature. Use the existing service only
when it is a provider adapter, a cross-boundary coordinator, a reporting/query boundary, or a
temporary facade required for compatibility.

Do not create a CRUD service merely to call create, update, or destroy on a model.

## Existing service behavior

Refactor only the coherent slice required by the current task:

1. Establish or extend focused Minitest coverage for the current observable behavior.
2. Identify the merchant-scoped model that owns the transition, association, or invariant.
3. Move that slice to a model method or a concern under the model namespace, retaining the service
   as a thin delegating facade until callers can move safely.
4. Update one caller boundary at a time: controller, job, or provider adapter.
5. Remove the facade only after its callers and focused tests are gone.

Preserve response behavior, transaction boundaries, logs/history, background-job idempotency, and
provider contracts. Do not fold a provider API client or Python Thrift adapter into an Active Record
model solely to eliminate a service.

## Checks

Before completion, confirm merchant scope is preserved, state transitions are transactional where
needed, resourceful routing remains clear, and jobs delegate to the domain owner. Run the focused
Docker-based Minitest and relevant JavaScript or system coverage.
