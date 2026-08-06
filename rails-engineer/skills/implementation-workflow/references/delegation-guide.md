# Skill Delegation Guide

> Fizzy profile only: examples here that use UUID ids, `account_id`, `Current.account`, or `params.expect`.
> Strip them for an ONCE-compatible application — see the target application's `AGENTS.md` under Rails Engineer Profile.

## When to Use Each Skill

### crud-patterns
Use when creating or modifying controllers.
- Creating new resource controllers with REST actions
- Modeling state changes as new resources (Closures, Publications)
- Nesting resources under parents
- Setting up routes

**Typical tasks:**
- "Create ProjectsController with CRUD actions scoped to Current.account"
- "Extract archive action into Projects::ArchivalsController"
- "Add nested CommentsController under Cards"

### rich-models-model-patterns
Use when creating or enriching domain models.
- Creating models with validations, associations, scopes
- Adding business logic methods to models
- Setting up callbacks (data normalization, after_create_commit)
- Configuring default values with Current attributes

**Typical tasks:**
- "Create Project model with rich domain logic and associations"
- "Move ProjectCreationService logic into Project.create_with_defaults"
- "Add mention detection to Comment model"

### concern-patterns
Use when extracting shared behavior.
- Shared model behavior across 2+ models (Closeable, Assignable)
- Controller scoping patterns (AccountScoped, ProjectScoped)
- Horizontal features that cut across multiple models

**Typical tasks:**
- "Extract Closeable concern from Card and Project models"
- "Create AccountScoped controller concern for query scoping"
- "Add Searchable concern with full-text search scopes"

### state-records
Use when modeling state changes.
- Converting booleans to state records (archived -> Archival)
- Implementing Closure, Publication, Goldness patterns
- Adding state with metadata (who changed it, when, why)

**Typical tasks:**
- "Implement Archival pattern replacing archived boolean on Project"
- "Create Publication model for project publishing workflow"
- "Add Closure pattern to Card and Task models via Closeable concern"

### testing-patterns
Use when writing or converting tests.
- Writing Minitest tests (model, controller, system)
- Creating YAML fixtures
- Converting RSpec to Minitest
- Replacing FactoryBot with fixtures

**Typical tasks:**
- "Create model and controller tests for Project with fixtures"
- "Add system test for project archival workflow"
- "Write fixtures for projects, cards, and their associations"

### rich-models-migration-patterns
Use when modifying database schema.
- Creating tables with UUIDs and account_id
- Adding columns with proper indexes
- Data backfill migrations
- No foreign key constraints (soft references only)

**Typical tasks:**
- "Create projects table with UUIDs, account_id, and indexes"
- "Add archivals table for state record pattern"
- "Backfill account_id on existing cards table"

### rich-models-job-patterns
Use for background processing.
- Creating Solid Queue jobs (no Redis)
- Following _later/_now convention on models
- Idempotent job design
- Recurring job setup

**Typical tasks:**
- "Create ExportJob that calls report.generate!"
- "Add export_later method to Report model"
- "Set up recurring cleanup job for expired sessions"

### rich-models-turbo-patterns
Use for real-time UI updates.
- Turbo Stream broadcasts from models
- Turbo Frames for isolated page sections
- Page morphing for live updates
- Broadcasting to multiple users

**Typical tasks:**
- "Add Turbo Stream broadcast to Comment for real-time updates"
- "Wrap project list in Turbo Frame for inline editing"
- "Broadcast card movements to all board viewers"

### rich-models-stimulus-patterns
Use for client-side JavaScript.
- Focused, single-purpose controllers
- Form enhancements (autosave, autocomplete)
- UI behaviors (toggle, modal, dropdown)
- Progressive enhancement (works without JS)

**Typical tasks:**
- "Create tag autocomplete Stimulus controller"
- "Add auto-expanding textarea controller"
- "Build drag-and-drop reordering with Stimulus"

### multi-tenant-setup
Use for account scoping.
- Setting up Account and Membership models
- URL-based multi-tenancy (/:account_id/...)
- Current.account context
- Data isolation verification

### auth-setup
Use for authentication.
- Custom passwordless magic links
- Session management
- Current.user and Current.session setup
- No Devise

### caching-patterns
Use for performance.
- HTTP caching with fresh_when and ETags
- Fragment caching in views
- Russian doll caching with touch: true
- Solid Cache configuration (no Redis)

### rich-models-mailer-patterns
Use for email.
- Minimal mailers with deliver_later
- Bundled/digest notifications
- Plain-text first templates
- after_create_commit for email triggers

### api-patterns
Use for JSON APIs.
- respond_to blocks in existing controllers
- Jbuilder view templates
- API token authentication
- Same controllers serve HTML and JSON

### event-tracking
Use for activity and audit.
- Domain event models (CardMoved, ProjectArchived)
- Polymorphic activity feeds
- Webhook delivery for external consumers

## Decision Matrix

| Need | Skill | Notes |
|------|-------|-------|
| New table | rich-models-migration-patterns | Always first in dependency chain |
| New model | rich-models-model-patterns | After migration |
| Shared behavior | concern-patterns | When 2+ models share code |
| Boolean to record | state-records | Includes migration + model + controller |
| New controller | crud-patterns | After model exists |
| Real-time updates | rich-models-turbo-patterns | After controller exists |
| Client interactivity | rich-models-stimulus-patterns | After views exist |
| Async operation | rich-models-job-patterns | For operations >500ms |
| Email | rich-models-mailer-patterns | Almost always with rich-models-job-patterns |
| Tests | testing-patterns | Throughout, after each layer |
