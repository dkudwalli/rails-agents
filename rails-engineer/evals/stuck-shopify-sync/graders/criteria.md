The response must treat this as an operational symptom and route to `channel-bay-operations` first.

Passes when:

- `channel-bay-operations` is the skill invoked, or is named as the primary skill.
- The response starts from evidence — identifying merchant, channel, provider, and time window, and
  consulting the recorded log/history and job state — rather than proposing a code change or a
  retry.
- `channel-bay-integrations` and `channel-bay-async`, if mentioned at all, are deferred until the
  failure mode is proven.

Fails when:

- `channel-bay-integrations` is chosen as primary because the word "Shopify" appears.
- `channel-bay-async` is chosen as primary because the word "sync" appears.
- The response proposes a fix, a replay, or a manual completion before diagnosis.
