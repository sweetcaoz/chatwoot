# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies
- `make setup` or `make burn`: Install dependencies (bundle + pnpm install)
- `bundle install`: Install Ruby gems
- `pnpm install`: Install Node.js packages

### Database Commands  
- `make db`: Prepare database for Chatwoot (`rails db:chatwoot_prepare`)
- `make db_create`: Create database
- `make db_migrate`: Run migrations
- `make db_seed`: Seed database with initial data
- `make db_reset`: Reset database (drop, create, migrate, seed)

### Running the Application
- `make run`: Start development server with Overmind (checks for existing instance)
- `make force_run`: Force start new development server instance
- `pnpm run dev` or `overmind start -f Procfile.dev`: Start all services (Rails server, Sidekiq worker, Vite)
- `make server`: Start Rails server only on port 3000
- `make console`: Start Rails console

### Testing and Quality
- `pnpm test`: Run JavaScript tests with Vitest (no watch mode)
- `pnpm run test:watch`: Run JavaScript tests in watch mode
- `pnpm run test:coverage`: Run JavaScript tests with coverage
- `bundle exec rspec`: Run Ruby/RSpec tests
- `pnpm run eslint`: Lint JavaScript/Vue files
- `pnpm run eslint:fix`: Fix ESLint issues automatically
- `bundle exec rubocop`: Lint Ruby code
- `bundle exec rubocop -a`: Auto-fix Ruby linting issues

### Development Tools
- `make debug`: Connect to backend process via Overmind
- `make debug_worker`: Connect to worker process via Overmind
- `pnpm run story:dev`: Start Histoire (component documentation)
- `pnpm run build:sdk`: Build JavaScript SDK

## Architecture Overview

Chatwoot is a Ruby on Rails application with a Vue.js frontend, following a standard Rails MVC pattern with additional modern web application patterns.

### Backend Architecture (Ruby on Rails)
- **Models** (`app/models/`): Core business logic, ActiveRecord models
  - Key models: `Account`, `User`, `Conversation`, `Message`, `Contact`, `Inbox`
  - Channel models in `app/models/channel/` (WebWidget, FacebookPage, TwitterProfile, etc.)
  - Concerns in `app/models/concerns/` for shared functionality
- **Controllers** (`app/controllers/`): API endpoints and request handling
  - API controllers in `app/controllers/api/` with versioned namespaces
  - Channel-specific controllers for webhooks
  - `super_admin/` controllers for admin panel
- **Services** (`app/services/`): Business logic and external integrations
- **Jobs** (`app/jobs/`): Background job processing with Sidekiq
- **Listeners** (`app/listeners/`): Event handling using Wisper gem
- **Policies** (`app/policies/`): Authorization logic using Pundit

### Frontend Architecture (Vue.js)
- **Dashboard App** (`app/javascript/dashboard/`): Main admin interface
  - Vue 3 with Composition API and Options API
  - Vuex for state management
  - Vue Router for routing
  - Component library in `components-next/` (newer design system)
- **Widget** (`app/javascript/widget/`): Customer-facing chat widget
- **Portal** (`app/javascript/portal/`): Help center/knowledge base
- **SDK** (`app/javascript/sdk/`): JavaScript SDK for integration

### Key Technologies
- **Backend**: Ruby 3.4.4, Rails 7.1, PostgreSQL, Redis, Sidekiq
- **Frontend**: Vue 3, Vite, TailwindCSS, Vitest for testing
- **Real-time**: ActionCable for WebSocket connections
- **Background Jobs**: Sidekiq with Redis
- **File Storage**: ActiveStorage with S3/Azure/GCS support
- **AI Features**: OpenAI integration, vector similarity (pgvector)

### Channel Architecture
Chatwoot supports multiple communication channels through a unified interface:
- Each channel type has its own model in `app/models/channel/`
- Channel-specific controllers handle webhooks and API callbacks
- Services handle message sending and receiving for each channel
- Supported channels: WebWidget, Facebook, Instagram, Twitter, WhatsApp, Telegram, Email, SMS

### Key Patterns
- **Concerns**: Shared functionality across models (labelable, avatarable, etc.)
- **Builders**: Object creation with complex logic
- **Finders**: Query objects for complex database operations  
- **Presenters**: Data presentation logic
- **Event-driven**: Uses Wisper for publishing/subscribing to domain events
- **Feature Flags**: `flag_shih_tzu` for feature toggles

### Database Schema
- Multi-tenant architecture with `Account` as the tenant boundary
- Core entities: Account → Inbox → Conversation → Message
- Contacts can have multiple conversations across different inboxes
- Rich metadata and custom attributes support
- Full-text search capabilities with pg_search

### Development Notes
- Uses `overmind` or `foreman` for process management
- Vite for asset bundling and hot module replacement
- Redis for caching, sessions, and background job queues
- Database migrations include both Rails migrations and custom rake tasks
- Comprehensive test coverage with RSpec (Ruby) and Vitest (JavaScript)

## Important Patterns & Common Issues

### Adding New Features
1. **Super Admin Navigation**: New controllers in `super_admin/` namespace require a corresponding Dashboard class in `app/dashboards/`
2. **Feature Flags**: Use FlagShihTzu's query methods like `Account.with_feature_kanban` instead of `Account.where(feature_kanban: true)`
3. **Frontend i18n**: Dashboard translations must be added to `app/javascript/dashboard/i18n/locale/en/` as JSON files and imported in the locale's index.js

### Kanban Feature
- Database: Uses `kanban_stages` table for stage configuration
- Feature flag: Controlled via `feature_kanban` in the account's feature_flags
- API endpoints: `/api/v1/accounts/:id/kanban/` namespace
- Frontend routes: `/accounts/:id/kanban/board` and `/accounts/:id/kanban/stages`
- Translations: `kanban.json` contains all UI strings

## Current Work & Context

### Project: Kanban Board Feature
**Status: Phase 1 Complete - Testing**

#### Business Goal
Provide a Kanban board where conversations are cards organized by pipeline stages. Admins configure stages, agents drag cards to move conversations through workflows. Zero changes to core conversation schema.

#### Current Phase Status
- ✅ **Phase 1: Core MVP** - COMPLETE, IN TESTING
  - kanban_stages table and model
  - Stage management API and UI
  - Drag-and-drop board with sparse ranking
  - Unread message prioritization
  - Dashboard integration
  
- 🚧 **Phase 1.5: Essential Polish** - NEXT
  - Automation action "Change Stage"
  - Real-time updates via ActionCable
  - Basic filters (assignee, inbox)
  - Mobile-responsive view

#### Key Technical Details
- **Data Storage**: Custom attributes (kanban_stage, kanban_position) - no core schema changes
- **API**: `/api/v1/accounts/:id/kanban/` namespace
- **Frontend**: Vue 3 components at `/accounts/:id/kanban`
- **Permissions**: Admins manage stages, agents move cards
- **Performance**: Sparse ranking algorithm, 50 cards/column limit

### Recently Completed
- Fixed Kanban feature from ProjectK release (Aug 2025)
  - Added missing KanbanSetupDashboard class for Super Admin navigation
  - Fixed feature flag queries to use FlagShihTzu syntax (`Account.with_feature_kanban` instead of `where(feature_kanban: true)`)
  - Added frontend i18n translations (kanban.json) and imported in locale index
  - Updated settings.json with "KANBAN": "Kanban Board" for sidebar

### Known Issues
- Redis deprecation warnings about blind passthrough in redis-namespace

### Project Preferences
- Run development server with `make run` or `pnpm run dev`
- Always check if migrations need to run after pulling changes
- Test super admin features at `/super_admin`
- Test kanban at `/app/accounts/:id/kanban` after enabling feature for account

### Design System Requirements
**IMPORTANT**: All new features MUST follow Chatwoot's design language:

1. **Use Chatwoot Components** (never raw HTML elements):
   - `woot-button` instead of `<button>` or `class="button"`
   - `woot-modal`, `woot-input`, `woot-switch` for forms
   - `fluent-icon` for all icons
   - `Thumbnail`, `TimeAgo`, `Spinner` for common UI elements

2. **Use CSS Variables** (never hardcoded values):
   - Colors: `--white`, `--s-200`, `--w-500`, `--color-body`, etc.
   - Spacing: `--space-small`, `--space-normal`, `--space-large`
   - Typography: `--font-size-default`, `--font-weight-bold`
   - Effects: `--shadow-medium`, `--border-radius-normal`

3. **Follow Existing Patterns**:
   - Check similar components in the codebase first
   - Modal structure should match other Chatwoot modals
   - Forms should use consistent layout patterns
   - Loading states should use Spinner component

4. **Component Imports**:
   - Global components (woot-*) don't need importing
   - Shared components from `dashboard/components/` or `shared/components/`
   - Always verify component exists before using