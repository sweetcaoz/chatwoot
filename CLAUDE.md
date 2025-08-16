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

### Chatwoot Design Patterns & Style Guide

**Visual Identity:**
- Clean, minimal interface with plenty of white space
- Rounded corners (--border-radius-normal, --border-radius-small)
- Subtle shadows (--shadow-small, --shadow-medium)
- Modern flat design with subtle depth

**Color System:**
- Primary: Blue (`--w-500`, `--w-600`) for actions and highlights
- Neutral: Gray scale (`--s-50` to `--s-900`) for text and backgrounds
- Success: Green (`--g-500`) for positive actions
- Warning: Yellow/Orange (`--y-500`) for cautions
- Error: Red (`--r-500`) for destructive actions
- Background: `--white` for cards, `--s-25` for page backgrounds

**Typography:**
- Font sizes: `--font-size-small`, `--font-size-default`, `--font-size-large`
- Font weights: `--font-weight-medium`, `--font-weight-bold`
- Line heights: Generous spacing for readability
- Text colors: `--s-900` for headings, `--s-700` for body text, `--s-600` for secondary text

**Spacing System:**
- Consistent spacing using: `--space-small`, `--space-normal`, `--space-large`, `--space-mega`
- Form elements: 16px (--space-normal) between fields
- Card padding: 20px (--space-large) for comfort
- Button spacing: 12px (--space-small) between buttons

**Component Patterns:**

1. **Cards & Containers:**
   ```scss
   .card {
     background: var(--white);
     border: 1px solid var(--s-200);
     border-radius: var(--border-radius-normal);
     padding: var(--space-large);
     box-shadow: var(--shadow-small);
   }
   ```

2. **Forms:**
   - Use `woot-input` for text fields
   - Label styling: `text-sm font-medium mb-1 block`
   - Form groups: `mb-4` spacing between fields
   - Help text: `text-xs text-gray-500 mt-1`
   - Error states: red border and text

3. **Buttons:**
   - Primary: `woot-button` with `color-scheme="primary"`
   - Secondary: `woot-button` with `variant="clear"`
   - Destructive: `color-scheme="alert"`
   - Sizes: `size="small"`, default, `size="large"`

4. **Modals:**
   - Use `woot-modal` component
   - Header: Clear title with close action
   - Body: Adequate padding and spacing
   - Footer: Right-aligned buttons with proper spacing
   - Max width: Reasonable for content (not full screen)

5. **Lists & Tables:**
   - Zebra striping for large datasets
   - Hover states for interactive rows
   - Consistent padding and alignment
   - Sort indicators for sortable columns

6. **Icons:**
   - Use `fluent-icon` exclusively
   - Standard sizes: 12, 16, 20, 24px
   - Consistent color: `--s-600` for inactive, `--s-800` for active
   - Proper alignment with text

7. **Loading States:**
   - Use `Spinner` component
   - Center alignment with descriptive text
   - Skeleton loaders for complex layouts

8. **Empty States:**
   - Large icon (48px) centered
   - Clear heading and description
   - Action button when applicable
   - Friendly, helpful messaging

**Layout Principles:**
- Mobile-first responsive design
- 12-column grid system where applicable
- Consistent header heights and navigation
- Sidebar navigation with clear hierarchy
- Breadcrumbs for deep navigation

**Interaction Patterns:**
- Subtle hover states (opacity, transform, shadow changes)
- Smooth transitions (0.2s ease)
- Clear focus indicators for accessibility
- Consistent click/tap targets (min 44px)

**Data Display:**
- Tables: Clean lines, adequate padding, sortable headers
- Cards: Consistent structure with header, body, footer
- Lists: Clear hierarchy and scannable content
- Metrics: Prominent numbers with context

**Always Reference:**
- Check existing similar components first
- Use Chatwoot's existing color picker, date picker, etc.
- Follow established naming conventions
- Test on both light and dark themes
- Ensure accessibility (ARIA labels, keyboard navigation)

## Phase 1 MVP Testing Checklist

### Pre-Testing Setup:
- [ ] Run `make setup` to install dependencies
- [ ] Run `rails kanban:install` to setup kanban feature
- [ ] Enable kanban for test account in Super Admin
- [ ] Restart dev server after any changes

### Super Admin Tests:
- [ ] Navigate to `/super_admin` - should load without 500 error
- [ ] Click "Kanban Setup" in navigation - should show setup page
- [ ] Check accounts with kanban enabled counter
- [ ] Test enable/disable kanban for accounts

### Kanban Board Tests:
- [ ] Navigate to `/app/accounts/:id/kanban` - should load board
- [ ] Empty state: Shows "No Stages Configured" with proper button
- [ ] Click "Configure Stages" - should navigate to stage manager
- [ ] Default stages: New, Qualified, Proposal, Negotiation, Closed
- [ ] Icons display correctly (sparkle, person-check, document, chat-multiple, checkmark-circle)
- [ ] Colors show properly for each stage
- [ ] Conversations load in appropriate stages
- [ ] Drag and drop conversations between stages
- [ ] Click conversation card - should open conversation view

### Stage Manager Tests:
- [ ] Navigate to `/app/accounts/:id/kanban/stages`
- [ ] List all stages with drag handles
- [ ] Click "Add Stage" - should open modal with form
- [ ] Form fields: Name (required), Key (required), Color picker, Icon dropdown
- [ ] Icon dropdown shows 15 options with proper labels
- [ ] Create new stage - should show success message
- [ ] Edit existing stage - should populate form correctly
- [ ] Key field disabled when editing
- [ ] Delete stage - should show confirmation modal
- [ ] Toggle stage active/inactive status
- [ ] Drag to reorder stages

### Translation Tests:
- [ ] All buttons show text (not COMMON.CANCEL, etc.)
- [ ] All labels show proper text (not raw translation keys)
- [ ] Error messages display correctly
- [ ] Success messages display correctly

### API Integration Tests:
- [ ] Network tab shows correct API endpoints
- [ ] GET /api/v1/accounts/:id/kanban/stages - loads stages
- [ ] POST /api/v1/accounts/:id/kanban/stages - creates stage
- [ ] PATCH /api/v1/accounts/:id/kanban/stages/:id - updates stage
- [ ] DELETE /api/v1/accounts/:id/kanban/stages/:id - deletes stage
- [ ] GET /api/v1/accounts/:id/kanban/board - loads board data
- [ ] POST /api/v1/accounts/:id/kanban/board/move - moves conversations

### Error Scenarios:
- [ ] Try accessing kanban without feature enabled
- [ ] Test with no conversations in account  
- [ ] Test with large number of conversations
- [ ] Test invalid stage data (empty name, duplicate key)
- [ ] Test network failures (API timeouts)

### Browser Console Tests:
- [ ] No JavaScript errors in console
- [ ] No Vue warnings about missing props/components
- [ ] No 404s for missing assets/translations
- [ ] No API 500 errors in network tab

### Responsive Design Tests:
- [ ] Desktop view (1200px+) - full board layout
- [ ] Tablet view (768px-1199px) - scrollable columns
- [ ] Mobile view (<768px) - single column stack

### Accessibility Tests:
- [ ] Keyboard navigation works for all interactive elements
- [ ] Screen reader compatible (proper ARIA labels)
- [ ] Focus indicators visible and logical
- [ ] Color contrast meets standards

# Recent Project Updates (Session: 2025-08-16)

## Critical Issues Resolved:

### 1. Stage Manager & Kanban UI Fixes:
- **Modal System**: Fixed broken "Add Stage" button by removing conflicting `showCreateModal` state - modal now opens properly
- **Auto-Generated Keys**: Stage keys now auto-generate from names (lowercase, underscores) - eliminated manual input requirement  
- **Design Consistency**: Applied proper Chatwoot styling - `--s-25` backgrounds, consistent spacing, proper layout
- **Button Positioning**: Fixed Stage Manager buttons appearing in wrong corner - now properly aligned in UI
- **UI Clarity**: Removed confusing "Manage conversations in a visual pipeline" subtitle for cleaner interface

### 2. Super Admin Integration Fixes:
- **Feature Flag Security**: Fixed `NoMethodError: with_feature_kanban` by implementing secure FlagShihTzu pattern:
  ```ruby
  # CORRECT & SECURE - Use bit operators with parameterized queries
  Account.where("feature_flags & ? > 0", Account.flag_mapping[:feature_kanban])    # enabled
  Account.where("feature_flags & ? = 0", Account.flag_mapping[:feature_kanban])    # disabled
  # NEVER use: Account.with_feature_kanban (doesn't exist)
  # NEVER expose raw SQL conditions for security
  ```
- **Navigation Structure**: Moved "Kanban Setup" to Settings dropdown (proper admin UX pattern)
- **Menu Integration**: Updated navigation helper to expand Settings menu when on Kanban Setup pages

### 3. Key Technical Patterns Established:
- **FlagShihTzu Security**: Always use parameterized bit operator queries for feature flags
- **Vue Modal Management**: Single source of truth for modal state - avoid conflicting booleans
- **Form Auto-Generation**: Watch field changes to auto-populate related fields for better UX
- **Admin Navigation**: Configuration pages belong in Settings dropdown, not standalone menus

## Current Status:
- ✅ **Phase 1 MVP**: Fully functional kanban board with drag-drop, stage management
- ✅ **Super Admin**: Secure setup interface properly integrated into Settings menu  
- ✅ **Design System**: Consistent Chatwoot styling applied throughout all components
- ⏳ **Next Phase**: Ready for Phase 1.5 (automation triggers, real-time updates, advanced filters)