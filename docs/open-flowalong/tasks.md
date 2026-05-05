
# FlowAlong Demo — Build Tasks

Track progress through each build phase. Check off tasks as completed. Run tests at the end of each phase before starting the next.

Full specifications and rationale for each phase are in [`docs/open-flowalong/flowalong-phases.md`](docs/open-flowalong/flowalong-phases.md).

---

## Phase 1 — Branding & Environment
**Goal:** App starts up as FlowAlong Demo with correct name, colors, and landing page.

### Implementation
- [x] Update `.env.example` — `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION`
- [x] Update local `.env` with same values
- [x] Replace accent block in `app/assets/stylesheets/application.css` with purple (`#8b5cf6`) + agenda card styles (combined into one file — Propshaft doesn't process local @import)
- [x] Add "My Workshops" and "New Workshop" nav links in layout (signed-in only, using literal paths until Phase 3 routes exist)
- [x] Replace `app/views/home/index.html.erb` with FlowAlong landing page
- [x] Update `app/views/dashboard/show.html.erb` with placeholder CTA (literal path)

### Manual Tests
- [ ] `/` shows FlowAlong headline, three-step row, purple CTA button
- [ ] Navbar shows "FlowAlong Demo" as app name
- [ ] Signed in: navbar shows "My Workshops" and "New Workshop"
- [ ] Signed out: nav links absent
- [ ] Accent color is purple on buttons and active nav

### RSpec
- [x] Run `bundle exec rspec` — all existing boilerplate specs pass (zero new failures)

---

## Phase 2 — Data Models & Migrations
**Goal:** `WorkshopBrief` and `WorkshopAgenda` exist with correct columns, validations, and associations.

### Implementation
- [x] Generate migration for `workshop_briefs` table (uuid pk, user_id, topic, audience, duration_minutes, desired_outcome, notes, timestamps)
- [x] Generate migration for `workshop_agendas` table (uuid pk, workshop_brief_id unique, user_id, title, body, gemini_raw, timestamps)
- [x] Run `rails db:migrate` — both tables created successfully
- [x] Create `app/models/workshop_brief.rb` with associations and validations
- [x] Create `app/models/workshop_agenda.rb` with associations and validations
- [x] Add `has_many :workshop_briefs` and `has_many :workshop_agendas` to `user.rb`
- [x] Create `spec/factories/workshop_briefs.rb`
- [x] Create `spec/factories/workshop_agendas.rb`
- [x] Update `config/database.yml` — renamed all databases from `open_base_*` to `open_flowalong_*`; updated production username and password env var

### Manual Tests
- [ ] `rails console`: `WorkshopBrief.new.valid?` → false
- [ ] `rails console`: valid brief with all required fields → `.valid?` → true
- [ ] `rails console`: `WorkshopAgenda.column_names` includes `workshop_brief_id`, `user_id`, `body`, `gemini_raw`

### RSpec
- [x] `spec/models/workshop_brief_spec.rb` — passing
  - [x] Validates presence: topic, audience, duration_minutes, desired_outcome
  - [x] Validates duration_minutes in [60, 90, 120]; rejects 45 and 180
  - [x] Validates length: topic ≤ 200, audience ≤ 200, desired_outcome ≤ 500, notes ≤ 1000
  - [x] notes is optional (blank passes)
  - [x] has_one :workshop_agenda, dependent: :destroy
  - [x] belongs_to :user
- [x] `spec/models/workshop_agenda_spec.rb` — passing
  - [x] Validates presence: workshop_brief_id, user_id, body
  - [x] belongs_to :workshop_brief
  - [x] belongs_to :user
  - [x] gemini_raw field stores and retrieves correctly

---

## Phase 3 — WorkshopBrief CRUD
**Goal:** Full brief lifecycle — create, read, update, delete. Dashboard shows brief index.

### Implementation
- [x] Add routes: `resources :workshop_briefs` with nested `resource :agenda`; replaced string path literals with route helpers in layout and views
- [x] Create `app/controllers/workshop_briefs_controller.rb` (index, new, create, show, edit, update, destroy)
- [x] Create `app/javascript/controllers/duration_selector_controller.js`
- [x] Create `app/views/workshop_briefs/index.html.erb` (grid + empty state)
- [x] Create `app/views/workshop_briefs/new.html.erb`
- [x] Create `app/views/workshop_briefs/edit.html.erb`
- [x] Create `app/views/workshop_briefs/_form.html.erb` (5 fields, duration toggle, btn-accent submit)
- [x] Create `app/views/workshop_briefs/show.html.erb` (two-column: brief summary + agenda placeholder/preview)
- [x] Update `app/controllers/dashboard_controller.rb` to redirect to `workshop_briefs_path`

### Manual Tests
- [ ] Sign in → redirected to `/workshop_briefs` (empty state visible)
- [ ] "New Workshop" → form renders with all five fields
- [ ] Duration buttons: selecting one highlights it purple, deselects others
- [ ] Submit valid form → redirected to show; brief summary visible
- [ ] Show page: right column shows "Your agenda will appear here."
- [ ] Show page: "Generate Agenda" button present
- [ ] Edit brief → change topic → save → updated topic on show
- [ ] Delete brief → confirm dialog → redirected to index → gone
- [ ] Access another user's brief URL → 404

### RSpec
- [x] `spec/requests/workshop_briefs_spec.rb` — passing
  - [x] GET /workshop_briefs → 200 for signed-in user
  - [x] GET /workshop_briefs → redirect to sign-in for unauthenticated
  - [x] POST /workshop_briefs valid params → creates brief, redirects to show
  - [x] POST /workshop_briefs missing topic → 422, re-renders form
  - [x] GET /workshop_briefs/:id → 200 for owner
  - [x] GET /workshop_briefs/:id → 404 for non-owner signed-in user
  - [x] PATCH /workshop_briefs/:id → updates and redirects
  - [x] DELETE /workshop_briefs/:id → destroys brief, redirects to index

---

## Phase 4 — AI Integration & Agenda Generation
**Goal:** Generate Agenda triggers Gemini; structured agenda renders as section cards; export works; errors display gracefully.

### Implementation
- [x] Add `gem "redcarpet"` to Gemfile
- [x] Add `flowalong_agenda_v1` template to `db/seeds.rb` (model: `gemini-2.5-flash`, temp: 0.5, max_tokens: 2500)
- [x] Create `app/controllers/workshop_agendas_controller.rb` (create, show, destroy, export)
- [x] Create `app/views/workshop_agendas/show.html.erb` (header, disclaimer, section card rendering, raw toggle)
- [x] Create `app/views/workshop_agendas/export.html.erb` (plain text, layout: false — renamed from `.text.erb` for format compatibility)
- [x] Add `render_agenda_markdown` helper to `ApplicationHelper` (redcarpet-based)
- [x] Wire brief show page: right column shows compact preview or placeholder; `shared/ai_error` when `@agenda_error` is set

### Manual Tests
- [ ] "Generate Agenda" → wait → redirected to agenda show page
- [ ] Agenda show: topic as h1, audience badge, duration badge
- [ ] Section cards render (not raw Markdown)
- [ ] Each card has purple time badge, section title, duration badge
- [ ] Facilitator Note in muted callout; Activity in purple-tinted box
- [ ] "Show raw Gemini response" toggle collapses/expands
- [ ] "Export / Print" → `text/plain` response with header block and footer disclaimer
- [ ] "Back to Brief" → brief show, right column shows compact agenda preview
- [ ] "Regenerate" on agenda page → deletes agenda → brief show with generate button
- [ ] Simulate Gemini error (remove API key) → error partial appears in right column, no crash
- [ ] Admin → AI Templates → `flowalong_agenda_v1` present with correct prompts, temperature 0.5

### RSpec
- [x] `spec/requests/workshop_agendas_spec.rb` — passing
  - [x] POST .../agenda calls GeminiService.generate with correct template and variables
  - [x] POST .../agenda creates WorkshopAgenda with body and gemini_raw
  - [x] POST .../agenda on TimeoutError → no agenda created; body includes timeout message
  - [x] POST .../agenda on BudgetExceededError → no agenda created; body includes budget message
  - [x] POST .../agenda called twice → first agenda deleted, new one created (count = 1)
  - [x] GET .../agenda → 200 for owner
  - [x] GET .../agenda → 404 for non-owner
  - [x] GET .../agenda → redirect to sign-in for unauthenticated
  - [x] GET .../agenda → 404 when no agenda exists
  - [x] GET .../agenda/export → Content-Type text/plain, includes agenda body and topic

---

## Phase 5 — Seeds & Dashboard Polish
**Goal:** `rails db:seed` produces two sample briefs (one with pre-written agenda) and the dashboard redirects to the brief index.

### Implementation
- [x] Add sample `WorkshopBrief` records to `db/seeds.rb`
- [x] Add pre-written `WorkshopAgenda` for Brief 1 (hand-authored, no API call at seed time)
- [x] Add Brief 2 with no agenda (so user can experience generation flow)
- [x] Dashboard controller redirects to `workshop_briefs_path` (done in Phase 3)

### Manual Tests
- [ ] `rails db:seed` on clean database — no errors
- [ ] Sign in → `/workshop_briefs` shows two brief cards
- [ ] "Running Effective Retrospectives" → agenda show with section cards
- [ ] "Introduction to Design Thinking..." → show page with "Your agenda will appear here."
- [ ] Admin → AI Templates → `flowalong_agenda_v1` seeded correctly

### RSpec
- [x] Run `bundle exec rspec` — full suite, zero failures

---

## Phase 6 — Testing & Polish
**Goal:** Full suite green; README updated; all edge cases covered; final UI review.

### Implementation
- [x] Add missing RSpec coverage
  - [x] GET .../agenda with no agenda → 404 (was already present from Phase 4)
  - [x] DELETE .../agenda with no agenda → redirect to brief (no crash)
  - [x] User B cannot POST .../agenda for User A's brief → 404 (was already present from Phase 4)
- [x] Update `README.md` with FlowAlong content (tagline, description, why I built this, prompt editing guide, setup)
- [x] Remove any `binding.pry` or debug artifacts (none found)
- [x] Add generation spinner + cancel button (`agenda_generator_controller.js`, wired to brief show page)

### Final Manual Test Checklist
- [x] No raw Markdown visible anywhere in the UI
- [x] All primary actions use btn-accent (purple)
- [x] All error states render shared error partial (no white screens)
- [x] "Show raw Gemini response" toggle works
- [x] Export returns text/plain with correct header/footer
- [x] Empty state displays correctly (no briefs)
- [x] Form validation errors display inline
- [x] Duration button group: nothing selected by default on new form; selected value persists on re-render after validation failure
- [x] Generation spinner appears and cancel button aborts the request

### RSpec
- [x] `bundle exec rspec --format documentation`
- [x] Zero failures
- [x] Zero real Gemini API calls in test output
- [x] All model, request, and service specs passing

---

## Notes

- Never start the Rails server from within a task — always tell the user to run it manually
- Never run `bundle exec rspec` automatically — ask the user to run it and share output
- Model: use `gemini-2.5-flash` (not `gemini-2.0-flash` — deprecated for new API keys)
- Turbo: always `turbo_stream.update` not `replace`
- JavaScript: Stimulus only — no plain JS, no inline handlers
- CSS: plain `.css` files — no SCSS compilation (Propshaft, no build tools)
