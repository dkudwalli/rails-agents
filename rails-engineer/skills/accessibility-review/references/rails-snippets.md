# Rails Accessibility Snippets

> **Profile routing:** Before copying a snippet, use `rails-testing` for RSpec or Minitest syntax, `rails-css` for Tailwind or plain CSS, and `rails-frontend` for ViewComponent or ERB-partial structure. Do not introduce an unselected stack.

These are Rails 8.1 + Hotwire remediations. Each stack-specific section names the profile value it
requires. Adapt namespaces and reuse the target application's existing test helpers, CSS tokens,
and view structure.

- Utility-class examples apply only when `CSS: tailwind`. With `CSS: plain`, keep the semantic
  markup and use the plain-CSS classes in section 6.
- The component class in section 5 applies only when `Views: viewcomponent`; an ERB-partial
  alternative follows it.
- The RSpec examples in section 7 apply only when `Testing: rspec`; Minitest routing follows them.

## 1. Layout skeleton (CSS: tailwind variant)

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <title><%= content_for?(:title) ? yield(:title) : "Application" %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="min-h-dvh bg-white text-gray-900">
    <a href="#main"
       class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2
              focus:z-50 focus:bg-white focus:px-3 focus:py-2 focus:rounded
              focus:ring-2 focus:ring-blue-600">
      Skip to main content
    </a>

    <header role="banner"><%= render "shared/navbar" %></header>

    <div id="flash"
         role="status"
         aria-live="polite"
         aria-atomic="true"
         class="sr-only-when-empty">
      <%= render "shared/flash" %>
    </div>

    <main id="main" tabindex="-1"><%= yield %></main>

    <footer role="contentinfo"><%= render "shared/footer" %></footer>
  </body>
</html>
```

Key points:

- `<html lang>` set (1.3.1 is already met; 3.1.1 covered).
- Skip link is the first focusable element (2.4.1).
- Live region for flash (4.1.3).
- `<main>` has `tabindex="-1"` so the focus-on-navigate controller below can
  move focus to it.

When `CSS: plain`, retain the same landmarks and ARIA attributes, replace the utility lists with
semantic classes such as `skip-link` and `flash-region`, and use section 6's plain-CSS definitions.

## 2. Focus-on-navigate Stimulus controller

Move focus to `<main>` after Turbo navigations so screen-reader users hear
the new page's heading (2.4.3, 4.1.3).

```js
// app/javascript/controllers/focus_main_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener("turbo:load", this.focusMain)
    document.addEventListener("turbo:frame-load", this.focusMain)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.focusMain)
    document.removeEventListener("turbo:frame-load", this.focusMain)
  }

  focusMain = () => {
    const main = document.getElementById("main")
    if (main) main.focus({ preventScroll: true })
  }
}
```

Attach on `<body data-controller="focus-main">` in the layout.

## 3. Accessible flash partial (CSS: tailwind variant)

```erb
<%# app/views/shared/_flash.html.erb %>
<% flash.each do |type, message| %>
  <div class="rounded-md px-4 py-3 <%= type == :alert ? 'bg-red-50 text-red-900' : 'bg-green-50 text-green-900' %>"
       role="<%= type == :alert ? 'alert' : 'status' %>">
    <%= message %>
  </div>
<% end %>
```

Polite for notices, assertive for alerts.

## 4. Form with accessible errors (CSS: tailwind variant)

```erb
<%= form_with model: @user, class: "space-y-4" do |f| %>
  <% if @user.errors.any? %>
    <div role="alert" class="rounded-md bg-red-50 p-4 text-red-900"
         data-controller="focus-on-mount">
      <h2 class="font-semibold">
        <%= pluralize(@user.errors.count, "error") %> prevented this save
      </h2>
      <ul class="list-disc pl-5">
        <% @user.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :email, class: "block font-medium" %>
    <%= f.email_field :email,
          required: true,
          autocomplete: "email",
          "aria-invalid": @user.errors[:email].any?,
          "aria-describedby": ("email-error" if @user.errors[:email].any?),
          class: "mt-1 block w-full rounded border-gray-300 focus:border-blue-600
                 focus:ring-2 focus:ring-blue-600" %>
    <% if @user.errors[:email].any? %>
      <p id="email-error" class="mt-1 text-sm text-red-700">
        <%= @user.errors[:email].to_sentence %>
      </p>
    <% end %>
  </div>

  <%= f.submit "Save", class: "rounded bg-blue-600 px-4 py-2 text-white
                                 focus-visible:ring-2 focus-visible:ring-offset-2
                                 focus-visible:ring-blue-600" %>
<% end %>
```

Companion Stimulus controller to focus the error summary on mount:

```js
// app/javascript/controllers/focus_on_mount_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  connect() { this.element.setAttribute("tabindex", "-1"); this.element.focus() }
}
```

For `CSS: plain`, keep the labels, error IDs, `aria-invalid`, `aria-describedby`, and focus behavior;
replace only the utility strings with the application's form and error-summary classes.

## 5. Icon button (profile-selected view structure)

### Views: viewcomponent

The utility list in this variant additionally requires `CSS: tailwind`. With `CSS: plain`, use the
`icon-button` class from section 6.

```ruby
# app/components/icon_button_component.rb
class IconButtonComponent < ViewComponent::Base
  def initialize(label:, icon:, **html_options)
    @label = label
    @icon = icon
    @html_options = html_options
  end

  def call
    content_tag :button,
                type: "button",
                "aria-label": @label,
                class: "inline-flex items-center justify-center p-2 rounded
                        min-h-[44px] min-w-[44px] focus-visible:ring-2
                        focus-visible:ring-blue-600 focus-visible:ring-offset-2
                        #{@html_options[:class]}",
                **@html_options.except(:class) do
      inline_svg_tag("#{@icon}.svg", class: "h-5 w-5", "aria-hidden": true)
    end
  end
end
```

Minimum touch target ≥ 44×44 (beats 2.5.8's 24×24 floor), explicit
`aria-label`, focus ring preserved.

### Views: erb-partials

Keep the same accessible name and touch target without introducing ViewComponent:

```erb
<%# app/views/shared/_icon_button.html.erb %>
<button type="button"
        aria-label="<%= label %>"
        class="icon-button <%= local_assigns[:class_name] %>">
  <%= inline_svg_tag "#{icon}.svg", aria: { hidden: true } %>
</button>
```

Use `rails-frontend` to place the partial according to the application's existing conventions.
The partial shows the `CSS: plain` class; a Tailwind application may substitute its existing
profile-approved utility list.

## 6. Profile-selected CSS helpers

### CSS: tailwind

Tailwind already provides `sr-only` and focus variants. Add only missing project-level behavior,
such as reduced-motion defaults; do not redefine framework utilities unless the application has a
recorded reason.

### CSS: plain

```css
/* app/assets/stylesheets/accessibility.css */

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.skip-link:focus {
  position: static;
  width: auto;
  height: auto;
  margin: 0;
  overflow: visible;
  clip: auto;
  white-space: normal;
}

.icon-button {
  align-items: center;
  display: inline-flex;
  justify-content: center;
  min-block-size: 44px;
  min-inline-size: 44px;
}

.icon-button:focus-visible,
.skip-link:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## 7. Accessibility checks in the profile-selected suite

### Testing: rspec

Use this only when the application already selects RSpec and has `axe-rspec` configured:

```ruby
# spec/system/accessibility/home_spec.rb
require "rails_helper"
require "axe-rspec"

RSpec.describe "Accessibility — home", :js, type: :system do
  it "has no axe violations" do
    visit root_path
    expect(page).to be_axe_clean
      .according_to(:wcag2a, :wcag2aa, :wcag22aa)
      .skipping("color-contrast") # only while tokens are being fixed
  end
end
```

Add a shared example to DRY across pages:

```ruby
# spec/support/shared_examples/accessible_page.rb
RSpec.shared_examples "an accessible page" do |path|
  it "passes axe-core at WCAG 2.2 AA" do
    visit path
    expect(page).to be_axe_clean.according_to(:wcag22aa)
  end
end
```

### Testing: minitest

Use `rails-testing` to place the equivalent check in the application's
`ApplicationSystemTestCase`. Reuse its installed axe/Capybara assertion helper; do not add
`axe-rspec`, RSpec matchers, or RSpec support directories. If the application has no Minitest axe
adapter, keep the system smoke test in Minitest and run the already-configured Pa11y or Lighthouse
check alongside it rather than changing test frameworks:

```ruby
# test/system/accessibility/home_test.rb
class HomeAccessibilityTest < ApplicationSystemTestCase
  test "exposes the home page to the configured accessibility checker" do
    visit root_path
    assert_selector "main"
    # Invoke the application's configured accessibility assertion here.
  end
end
```

## 8. `rails generate` helper for accessible CRUD views

Override the scaffold templates at `lib/templates/erb/scaffold/` so new
forms ship with labels, `autocomplete`, and `aria-describedby` for errors by
default. This removes a whole class of regressions at the generator level.

## 9. Brakeman-style a11y pre-commit check

If the application already uses a pre-commit runner, configure it to run Herb and the existing
Pa11y check against a local server before commits touching view files. For `Views: viewcomponent`,
lint `app/views app/components`; for `Views: erb-partials`, lint `app/views`. Keep a new CI check
non-blocking until its baseline is green.

## 10. Language switcher

```erb
<nav aria-label="Language">
  <ul class="language-switcher">
    <% I18n.available_locales.each do |locale| %>
      <li>
        <%= link_to t("languages.#{locale}"),
              url_for(locale: locale),
              lang: locale.to_s,
              "aria-current": ("true" if I18n.locale == locale) %>
      </li>
    <% end %>
  </ul>
</nav>
```

`lang` on each link marks the language of the link text (3.1.2);
`aria-current` announces the active choice (4.1.2).
