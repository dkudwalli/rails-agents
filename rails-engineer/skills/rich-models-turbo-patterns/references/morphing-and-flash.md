# Morphing and Flash Reference

## Morphing

Use `turbo_stream.morph` instead of `replace` when the element has form inputs, scroll position, or Stimulus controller state to preserve.

### Enable globally

```html
<meta name="turbo-refresh-method" content="morph">
<meta name="turbo-refresh-scroll" content="preserve">
```

### Per-element control

```erb
<div id="<%= dom_id(@card) %>" data-turbo-permanent>
  <%# Persists across page loads %>
</div>
```

## Flash messages with Turbo

```ruby
# app/controllers/concerns/turbo_flash.rb
module TurboFlash
  extend ActiveSupport::Concern

  private

  def turbo_notice(message)
    turbo_stream.prepend "flash", partial: "shared/flash",
      locals: { type: :notice, message: message }
  end
end
```
