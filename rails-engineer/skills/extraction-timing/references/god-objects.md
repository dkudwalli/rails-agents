# God Object Detection

For models past 300 lines, line count has stopped being informative. A 280-line model with low complexity
and one responsibility is fine. A 200-line model that changes every week and scores 140 on flog is not.
The question at this size is **churn x complexity**, not size.

## Measuring

```bash
# Churn -- how often this file changes
git log --format=oneline --since="6 months ago" -- app/models/user.rb | wc -l

# Complexity -- flog score (gem install flog)
flog -s app/models/user.rb

# Both at once, ranked (gem install attractor)
attractor report -p app/models
```

Files high in **both** are the refactoring candidates. High churn with low complexity means an area under
active development -- leave it alone. High complexity with low churn means settled code that nobody needs
to touch -- also leave it alone. It's the intersection that costs you.

Find the intersection by hand when `attractor` isn't available:

```bash
# Top 10 by churn
git log --format=%n --name-only --since="6 months ago" -- 'app/models/*.rb' \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -10

# Top 10 by complexity
flog -s app/models/*.rb | head -12
```

## Structural Thresholds

Count these alongside the metrics. Any single axis in the critical column is worth investigating; two or
more is a god object.

| Axis | Warning | Critical |
|------|---------|----------|
| Lines | 150 | 300 |
| Public methods | 20 | 40 |
| Associations | 10 | 20 |
| Callbacks | 5 | 10 |
| Concerns included | 5 | 10 |
| Scopes | 10 | 20 |

The usual suspects, because they accumulate responsibilities by default: `User`, `Account`, `Order`,
`Transaction`, `Project`, `Workspace`, `Post`.

## Size Alone Is Not the Verdict

Report a large model as a **non-issue** when it has:

- Low complexity despite the line count (long but flat -- lots of scopes, delegations, or constants)
- A single coherent responsibility
- Churn that comes from feature additions rather than bug fixes

A model can be big because the domain concept is big. Splitting it produces two files that always change
together, which is worse than one file that's long. Say "monitor, no action" and move on.

The signal that a big model is a real problem is **churn from bug fixes** -- it means people can't change
one part without breaking another.

## Decomposition Strategies

In order of preference. Stop at the first one that fits.

1. **Concern** -- a cohesive slice of behavior that could be tested without instantiating the host model.
   Cheapest move. If you can't write specs for it standalone, it's code-slicing, not a concern -- skip to 2.
2. **Collaborator object** -- a PORO or associated model owning one slice of the model's behavior, delegated
   to so call sites don't change (`user.billing.charge!`). Right when the slice has real logic, not just
   grouped declarations.
3. **Value object** -- a group of related attributes with no identity of their own (money, address, date
   range). Use `Data.define` or `composed_of`.
4. **Separate model** -- when the slice has its own identity and lifecycle. The most expensive move; it
   needs a migration.

Before any of these, check the callbacks. A model with 10 callbacks is often not a god object at all --
it's a model with an operation-callback problem. Score them first (see the main SKILL.md rubric); extracting
the score-1 and score-2 callbacks to services frequently drops the model below the warning line on its own.

## Analyzing a Candidate

1. Measure churn and complexity; confirm it's in the intersection.
2. Count the structural axes above.
3. Group the public methods by responsibility, with line ranges. This is where the split shows itself -- if
   the methods fall into 3 clean groups, you have 3 candidates; if they don't group, it's not a god object,
   it's just long.
4. Check for layer violations inside the model (mailers, HTTP clients, `Current`, job enqueues).
5. Pick the cheapest decomposition per group.
