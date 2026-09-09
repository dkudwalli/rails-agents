# Routing evals

This plugin is nine skill descriptions and some prose. Whether those descriptions fire, and whether
overlapping ones resolve in the intended order, *is* the product — so it is the thing worth testing.
`scripts/verify_plugins.sh` checks structure and that every referenced document resolves. It cannot
check routing behavior. These cases do.

## Running

    claude plugin eval ./rails-engineer --ablation with-without --threshold 0.8

`--ablation with-without` adds a no-plugin baseline arm and reports the delta, which is the number
that matters here: a case the model answers correctly without the plugin proves nothing about the
plugin.

Run these manually. Each case costs model calls, so they are deliberately not wired into
`scripts/release_check.sh` or CI.

**These cases have never been executed.** `claude plugin eval` is gated behind early access and
refused to run on the authoring account, so the one-directory-per-case layout with
`graders/criteria.md` is taken from `claude plugin eval init --help` rather than from a scaffold the
tool produced. `--help` also documents a `case.yaml` form. If the first run reports a format error,
suspect this layout before your setup, and reconcile against `claude plugin eval init --bare`.

## What each case pins

| Case | Pins |
|---|---|
| stuck-shopify-sync | An operational symptom routes to operations first, not to the provider skill |
| amazon-job-retry | Async is primary for queue/retry behavior; integrations is secondary |
| product-archive-method | New local CRUD goes to the model, not a new service object |
| pr-merge-safety | Review fires for assessment rather than an implementation skill |
| plain-rails-question | No ChannelBay skill fires for generic Rails work |

The first two exist because the descriptions overlap: `channel-bay-operations` claims diagnosis of
syncs, `channel-bay-integrations` claims "changing **or investigating**" a provider boundary, and
`channel-bay-async` claims sync-progress. One prompt can match all three. `rails-guide` states the
precedence; these cases check the statement has an effect.
