# Stimulus Performance and Testing Reference

## Performance tips

1. **Event delegation:** One listener on parent, not many on children
2. **Debounce expensive ops:** Use `setTimeout` with clear pattern
3. **Every `connect()` that starts something has a `disconnect()` that stops it**
4. **Use `<target>TargetConnected` / `TargetDisconnected`** instead of a MutationObserver — Stimulus
   already watches the DOM for you
5. **Arrow-function class fields** where listener identity matters, so `removeEventListener` can find
   the same reference

```javascript
export default class extends Controller {
  #close = (event) => { /* stable identity, removable */ }

  connect() {
    document.addEventListener("click", this.#close)
  }

  disconnect() {
    clearTimeout(this.timeout)
    document.removeEventListener("click", this.#close)
  }
}
```

## Testing

```ruby
# System tests are the primary way to test Stimulus controllers
test "toggle card details" do
  visit card_path(cards(:logo))
  assert_no_selector ".card__details"
  click_button "Show Details"
  assert_selector ".card__details"
end
```
