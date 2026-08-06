# Testing Strategy by Layer

What to test where, and how much. The worked spec files live with the layer they test — this file
routes to them and holds only what spans layers.

## Test Pyramid

```
        /\
       /  \  System Specs (few)
      /----\
     /      \  Request Specs (moderate)
    /--------\
   /          \  Unit Specs (many)
  --------------
  Models, Services, Queries, Presenters
```

## Where the specs live

| Layer | Test type | Focus | Worked specs |
|-------|-----------|-------|--------------|
| Model | Unit | Validations, scopes, enums, callbacks | [`layered-model-patterns`](../../layered-model-patterns/references/testing-and-factories.md) |
| Service | Unit | Success and failure paths, side effects, transactions | [`service-patterns`](../../service-patterns/references/testing.md) |
| Query | Unit | Results, tenant isolation, N+1 | [`query-patterns`](../../query-patterns/references/testing.md) |
| Presenter | Unit | Formatting, HTML output | [`presenter-patterns`](../../presenter-patterns/references/testing.md) |
| Form | Unit | Multi-model validation, view wiring | [`form-patterns`](../../form-patterns/references/testing-and-views.md) |
| Policy | Unit | Every action for every role | [`policy-patterns`](../../policy-patterns/references/testing-and-controllers.md) |
| Controller | Request | HTTP flow, authorization, redirects | [`controller-patterns`](../../controller-patterns/references/request-specs.md) |
| Component | Component | Rendering, variants, previews | [`viewcomponent-patterns`](../../viewcomponent-patterns/references/testing-and-previews.md) |
| System | E2E | Critical user paths | (below) |

The house rules for specs — naming, `subject(:result)`, Shoulda Matchers, factory placement — are in
[`layered-conventions/references/testing.md`](../../layered-conventions/references/testing.md).

## System Specs

The one layer with no pattern skill of its own. Keep them few and reserved for paths where a broken
step costs a customer.

```ruby
# spec/system/create_event_spec.rb
require "rails_helper"

RSpec.describe "Creating an event", type: :system do
  let(:user) { create(:user) }
  let(:account) { user.account }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  it "creates an event and shows it on the dashboard" do
    visit new_event_path

    fill_in "Name", with: "Annual Gala"
    fill_in "Date", with: 1.month.from_now.to_date
    click_button "Create event"

    expect(page).to have_content("Event was successfully created")
    expect(page).to have_content("Annual Gala")
    expect(account.events.count).to eq(1)
  end
end
```

## Cross-Layer Helpers

Multi-tenancy is tested the same way in every layer, so the assertion belongs in one shared example
rather than in each spec. The definition and a usage example are in
[`query-patterns/references/testing.md`](../../query-patterns/references/testing.md) § Testing Tenant
Isolation — include it from model, service, and policy specs too.

Factory conventions and traits: [`layered-model-patterns`](../../layered-model-patterns/references/testing-and-factories.md)
§ FactoryBot Factories.

## Coverage Requirements

| Layer | Minimum coverage |
|-------|-----------------|
| Models | 90% |
| Services | 95% |
| Queries | 90% |
| Controllers | 80% |
| Overall | 85% |
