This is a change to queue and retry behavior on a job that happens to talk to a provider.

Passes when:

- `channel-bay-async` is primary, and `channel-bay-integrations` is consulted for the SP-API
  protocol and rate-limit constraints rather than being treated as the whole task.
- Idempotency is raised: a retry must not duplicate the external call or corrupt batch state.
- `channel-bay-testing` is named for the duplicate/retry coverage.

Fails when:

- Only one of async or integrations is considered and the other is never mentioned.
- The response proposes switching queue backends, or introduces Sidekiq or Redis.
