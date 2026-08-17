# Controller Structure Reference

## Controller structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static classes = ["active", "hidden"]
  static values = {
    url: String,
    timeout: { type: Number, default: 5000 }
  }

  connect() { /* Setup */ }
  disconnect() { /* Cleanup -- always clean up! */ }

  actionMethod(event) {
    event.preventDefault()
    this.element.classList.toggle(this.activeClass)
  }

  #privateHelper() { /* Use # prefix */ }
}
```

## Naming conventions

- **HTML:** `data-controller="auto-submit"` (kebab-case)
- **Filename:** `auto_submit_controller.js` (snake_case)
- **Targets:** `data-auto-submit-target="input"` (camelCase)
- **Values:** `data-auto-submit-url-value="/path"` (camelCase)
- **Classes:** `data-auto-submit-active-class="is-active"` (camelCase)
