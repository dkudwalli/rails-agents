An assessment request, not an implementation request.

Passes when:

- `channel-bay-review` is invoked.
- Findings are ordered by severity and start from the changed merchant, channel, provider, and
  webhook boundaries rather than generic Rails style.
- Product-mapping identity is checked on `source_variant_id` and mapping configuration, not on a
  displayed SKU.
- Duplicate and out-of-order webhook delivery is considered.

Fails when:

- An implementation skill is invoked and the branch is edited instead of assessed.
- The review reports only style or naming observations.
