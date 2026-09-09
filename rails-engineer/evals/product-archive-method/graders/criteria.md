New local domain behavior. The 37signals direction is the default here.

Passes when:

- `37signals-conventions` is invoked, paired with `channel-bay-backend`.
- The behavior lands on the `Product` model or a model-namespaced concern — not in a new service
  object under `app/services`.
- Because history is retained, a record-based state change and a resourceful route are preferred
  over a custom member action with a boolean column.
- Merchant scoping is preserved on every read and write.

Fails when:

- A new `ProductArchiveService` or similar CRUD service is proposed.
- The existence of `app/services` is treated as a reason to put the behavior there.
