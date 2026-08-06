# Rails application guidance

Keep application-specific guidance above or below this section. Run the `rails-onboard` skill to
detect and confirm this application's choices; it replaces only the marked section below.

<!-- rails-engineer:profile:start -->
## Rails Engineer Profile

Architecture: <layered|rich-models>
Testing: <rspec|minitest>
CSS: <tailwind|plain>
Views: <viewcomponent|erb-partials>
Database: <postgres|sqlite|mysql>
IDs: <uuidv7|integer>
Authorization: <pundit|scoped-model>
Authentication: <secure-password|session-record>
Runtime: <solid|redis-resque>
Assets: <importmap|node-bundler>
Tenancy: <single|multi>
Deployment: <kamal|docker-procfile>
Workflow: <sdd|conventional>
Application kind: <new|existing>
Source: <selected for a new application|detected from the existing application>
Rationale: <why this profile fits the product>

## Deliberate divergences

- <a deliberately mixed choice and why it remains>

## Profile-first instruction

Read this profile before proposing implementation changes. A recorded deliberate divergence is a
decision, not migration work.
<!-- rails-engineer:profile:end -->
