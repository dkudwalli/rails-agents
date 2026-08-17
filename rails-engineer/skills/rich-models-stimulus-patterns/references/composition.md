# Controller Composition Reference

## Multiple controllers on one element

```erb
<div data-controller="dropdown modal">
  <%# Both controllers active %>
</div>
```

## Nested controllers

```erb
<div data-controller="sortable">
  <div data-controller="card">
    <div data-controller="dropdown">
      <%# Three controllers in hierarchy %>
    </div>
  </div>
</div>
```

## Controller communication via events

```javascript
// Publisher dispatches
this.dispatch("published", { detail: { content: "data" } })

// Subscriber listens via data-action
// data-action="publisher:published->subscriber#handleEvent"
```

## Talking to other controllers

Use `this.dispatch` and Stimulus outlets. Never import one controller into another — that couples two
behaviours that the HTML is supposed to compose.
