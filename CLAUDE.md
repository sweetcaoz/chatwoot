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