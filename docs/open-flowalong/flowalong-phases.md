# FlowAlong Demo — Phased Build Specification

**Built on:** Open Demo Starter v2.0
**Accent:** `#8b5cf6` (purple)
**License:** MIT

This document breaks the FlowAlong demo build into discrete, sequentially executable phases. Each phase ends with manual acceptance tests and RSpec targets. Complete all tests before starting the next phase.

---

## Notes on the Source Spec

Two corrections applied from `docs/ai-templates.md` vs. the app spec:

1. **CSS files:** The boilerplate uses Propshaft with no SCSS compilation. The spec references `_accent.scss` and `_agenda.scss` — these are written as plain `.css` files and imported via `application.css`.
2. **Gemini model:** The spec lists `gemini-2.0-flash` but `docs/ai-templates.md` explicitly marks that model as deprecated for new API keys. Use `gemini-2.5-flash` in the seed and test accordingly.

---

## Phase 1 — Branding & Environment

**Goal:** The app starts up as FlowAlong Demo with the correct name, tagline, colors, and landing page. No domain models yet.

### 1.1 Environment variables

Update `.env.example`:
```
APP_NAME=FlowAlong Demo
APP_TAGLINE=Give it a topic and a time limit. Get a complete workshop agenda with activities.
APP_DESCRIPTION=AI-generated workshop agendas for facilitators, educators, and team leads.
```
Copy the same values to your local `.env`.

### 1.2 Accent color

Replace the accent block in `app/assets/stylesheets/application.css`:
```css
:root {
  --accent: #8b5cf6;
  --accent-hover: #7c3aed;
}

.btn-accent {
  background-color: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

.btn-accent:hover {
  background-color: var(--accent-hover);
  border-color: var(--accent-hover);
  color: #fff;
}
```

### 1.3 Agenda CSS

Add a new file `app/assets/stylesheets/agenda.css`:
```css
.agenda-section-card {
  border-left: 3px solid var(--accent);
  margin-bottom: 1.5rem;
}

.agenda-time-badge {
  background-color: var(--accent);
  color: #fff;
  font-size: 0.75rem;
  padding: 0.25rem 0.6rem;
  border-radius: 0.25rem;
  font-family: monospace;
}

.agenda-activity-box {
  background-color: rgba(139, 92, 246, 0.08);
  border-radius: 0.25rem;
  padding: 0.75rem 1rem;
}
```

Import it at the bottom of `application.css`:
```css
@import "agenda.css";
```

### 1.4 Navbar links

In `app/views/layouts/application.html.erb`, add inside the signed-in nav section:
```erb
<%= link_to "My Workshops", workshop_briefs_path, class: "nav-link" %>
<%= link_to "New Workshop", new_workshop_brief_path, class: "nav-link" %>
```
Both links are wrapped in `<% if current_user %>` so they only appear when signed in.

### 1.5 Landing page

Replace `app/views/home/index.html.erb` with the FlowAlong landing page:
- Headline: "Give it a topic. Get a complete workshop agenda."
- One paragraph explaining the problem (workshop design requires years of experience)
- Three-step "How It Works" row: Fill in your brief → Generate the agenda → Facilitate with confidence
- Sample agenda preview card (static HTML snippet showing a few sections)
- CTA button linking to `sign_up_path` using `btn-accent`

### 1.6 Dashboard redirect

The boilerplate dashboard (`app/views/dashboard/show.html.erb`) will be replaced in Phase 3 when the brief index exists. For now, add a simple "Create your first workshop" button pointing to `new_workshop_brief_path`.

### Phase 1 — Manual Tests

- [ ] Visit `/` — see FlowAlong headline, three steps, CTA button
- [ ] Navbar shows "FlowAlong Demo" as the app name
- [ ] Sign in as `demo@example.com` / `password123` — navbar shows "My Workshops" and "New Workshop"
- [ ] Accent color is purple on the CTA button and any active nav link
- [ ] Sign out — "My Workshops" and "New Workshop" links disappear

### Phase 1 — RSpec

No new RSpec targets for Phase 1. The existing boilerplate suite should still pass:
```bash
bundle exec rspec
```
Confirm zero failures before proceeding.

---

## Phase 2 — Data Models & Migrations

**Goal:** `WorkshopBrief` and `WorkshopAgenda` exist in the database with correct columns, associations, and validations. Factories are in place.

### 2.1 WorkshopBrief migration

```ruby
create_table :workshop_briefs, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid
  t.string  :topic,            null: false
  t.string  :audience,         null: false
  t.integer :duration_minutes, null: false
  t.text    :desired_outcome,  null: false
  t.text    :notes
  t.timestamps null: false
end
```

### 2.2 WorkshopAgenda migration

```ruby
create_table :workshop_agendas, id: :uuid do |t|
  t.references :workshop_brief, null: false, foreign_key: true, type: :uuid
  t.references :user,           null: false, foreign_key: true, type: :uuid
  t.string :title,       null: false
  t.text   :body,        null: false
  t.text   :gemini_raw
  t.timestamps null: false
end

add_index :workshop_agendas, :workshop_brief_id, unique: true
```

The unique index enforces one agenda per brief at the database level.

### 2.3 WorkshopBrief model

```ruby
# app/models/workshop_brief.rb
class WorkshopBrief < ApplicationRecord
  belongs_to :user
  has_one :workshop_agenda, dependent: :destroy

  validates :topic,            presence: true, length: { maximum: 200 }
  validates :audience,         presence: true, length: { maximum: 200 }
  validates :duration_minutes, presence: true, inclusion: { in: [60, 90, 120] }
  validates :desired_outcome,  presence: true, length: { maximum: 500 }
  validates :notes,            length: { maximum: 1000 }, allow_blank: true
end
```

### 2.4 WorkshopAgenda model

```ruby
# app/models/workshop_agenda.rb
class WorkshopAgenda < ApplicationRecord
  belongs_to :workshop_brief
  belongs_to :user

  validates :workshop_brief_id, presence: true
  validates :user_id,           presence: true
  validates :body,              presence: true
end
```

### 2.5 User model association

Add to `app/models/user.rb`:
```ruby
has_many :workshop_briefs,  dependent: :destroy
has_many :workshop_agendas, dependent: :destroy
```

### 2.6 Factories

**`spec/factories/workshop_briefs.rb`:**
```ruby
FactoryBot.define do
  factory :workshop_brief do
    user
    topic            { "Running Effective Retrospectives" }
    audience         { "Software engineering teams and their managers" }
    duration_minutes { 90 }
    desired_outcome  { "Teams leave with a specific retro format they can use immediately" }
    notes            { "" }
  end
end
```

**`spec/factories/workshop_agendas.rb`:**
```ruby
FactoryBot.define do
  factory :workshop_agenda do
    workshop_brief
    user    { workshop_brief.user }
    title   { workshop_brief.topic }
    body    { "## 00:00 - Welcome and Framing (10 min)\n\n**Facilitator Note:** Welcome participants.\n\n**Activity:** Pair share.\n\n---" }
    gemini_raw { body }
  end
end
```

### Phase 2 — Manual Tests

- [ ] Run `rails db:migrate` — no errors
- [ ] Open `rails console`:
  - `WorkshopBrief.new.valid?` → false (missing required fields)
  - `WorkshopBrief.new(topic: "Test", audience: "Devs", duration_minutes: 60, desired_outcome: "x", user: User.first).valid?` → true
  - `WorkshopAgenda.column_names` includes `workshop_brief_id`, `user_id`, `body`, `gemini_raw`

### Phase 2 — RSpec

**`spec/models/workshop_brief_spec.rb`:**
- [ ] Validates presence of `topic`, `audience`, `duration_minutes`, `desired_outcome`
- [ ] Validates `duration_minutes` is in `[60, 90, 120]`; rejects `45` and `180`
- [ ] Validates `topic` max 200 chars, `audience` max 200, `desired_outcome` max 500, `notes` max 1000
- [ ] `notes` is optional (blank passes validation)
- [ ] `has_one :workshop_agenda, dependent: :destroy` — destroying a brief destroys its agenda
- [ ] `belongs_to :user`

**`spec/models/workshop_agenda_spec.rb`:**
- [ ] Validates presence of `workshop_brief_id`, `user_id`, `body`
- [ ] `belongs_to :workshop_brief`
- [ ] `belongs_to :user`
- [ ] `gemini_raw` field is stored and retrievable

---

## Phase 3 — WorkshopBrief CRUD

**Goal:** Users can create, view, edit, and delete workshop briefs. The dashboard shows the brief index. The brief show page is the UX anchor for the rest of the app.

### 3.1 Routes

```ruby
# config/routes.rb
resources :workshop_briefs do
  resource :agenda, controller: "workshop_agendas", only: [:create, :show, :destroy] do
    get :export, on: :member
  end
end
```

This gives:
- `GET /workshop_briefs` → `workshop_briefs#index`
- `GET /workshop_briefs/new` → `workshop_briefs#new`
- `POST /workshop_briefs` → `workshop_briefs#create`
- `GET /workshop_briefs/:id` → `workshop_briefs#show`
- `GET /workshop_briefs/:id/edit` → `workshop_briefs#edit`
- `PATCH /workshop_briefs/:id` → `workshop_briefs#update`
- `DELETE /workshop_briefs/:id` → `workshop_briefs#destroy`
- `POST /workshop_briefs/:workshop_brief_id/agenda` → `workshop_agendas#create`
- `GET /workshop_briefs/:workshop_brief_id/agenda` → `workshop_agendas#show`
- `DELETE /workshop_briefs/:workshop_brief_id/agenda` → `workshop_agendas#destroy`
- `GET /workshop_briefs/:workshop_brief_id/agenda/export` → `workshop_agendas#export`

### 3.2 WorkshopBriefsController

```ruby
# app/controllers/workshop_briefs_controller.rb
class WorkshopBriefsController < ApplicationController
  before_action :set_brief, only: [:show, :edit, :update, :destroy]

  def index
    @briefs = current_user.workshop_briefs.order(updated_at: :desc)
  end

  def new
    @brief = WorkshopBrief.new
  end

  def create
    @brief = current_user.workshop_briefs.build(brief_params)
    if @brief.save
      redirect_to @brief, notice: "Workshop brief created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @agenda = @brief.workshop_agenda
  end

  def edit; end

  def update
    if @brief.update(brief_params)
      redirect_to @brief, notice: "Brief updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @brief.destroy
    redirect_to workshop_briefs_path, notice: "Workshop deleted."
  end

  private

  def set_brief
    @brief = current_user.workshop_briefs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  def brief_params
    params.require(:workshop_brief).permit(:topic, :audience, :duration_minutes, :desired_outcome, :notes)
  end
end
```

### 3.3 Duration Selector Stimulus controller

The duration field uses three toggle buttons. A Stimulus controller updates a hidden integer input and styles the active button.

```javascript
// app/javascript/controllers/duration_selector_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "input"]

  select(event) {
    const selected = event.currentTarget
    this.buttonTargets.forEach(btn => btn.classList.remove("btn-accent", "active"))
    selected.classList.add("btn-accent", "active")
    this.inputTarget.value = selected.dataset.value
  }
}
```

### 3.4 Views

**`app/views/workshop_briefs/index.html.erb`:**
- Page header: "My Workshops" h1 + "New Workshop" btn-accent button (top right)
- Empty state: centered card with "You haven't created any workshops yet" + "Create your first workshop" btn-accent
- Brief grid: `row` / `col-md-4` per brief, card with topic, audience, duration badge, relative timestamp, link to show

**`app/views/workshop_briefs/new.html.erb`** and **`edit.html.erb`:**
- Both render `_form.html.erb` inside `col-md-8 col-lg-6 mx-auto`

**`app/views/workshop_briefs/_form.html.erb`:**
- Topic: text_field, required, placeholder "e.g. Psychological Safety in Engineering Teams"
- Audience: text_field, required, placeholder "e.g. Engineering managers and team leads"
- Duration: three buttons (60 min / 90 min / 120 min) + hidden field, wired to `duration-selector` controller
- Desired Outcome: textarea, 3 rows, required, placeholder
- Additional Notes: textarea, 2 rows, optional, helper text
- Submit: btn-accent, Cancel: link to `workshop_briefs_path`
- Render `shared/error_messages` partial if `@brief.errors.any?`

**`app/views/workshop_briefs/show.html.erb`:**
Two-column layout:
- Left `col-md-4`: Brief summary card (topic, audience, duration, desired outcome, notes). Edit link, Delete link (turbo-method delete with confirm). If no agenda: "Generate Agenda" `button_to` (POST to `workshop_brief_agenda_path`). Disclaimer beneath button.
- Right `col-md-8`: If agenda exists — compact preview card showing first section, "View Full Agenda" link. If no agenda — placeholder card with muted "Your agenda will appear here." If `@agenda_error` instance variable set — render `shared/ai_error` partial at top of right column.

**`app/views/dashboard/show.html.erb`:**
Replace with redirect logic or simply render the same content as `workshop_briefs/index`. The cleanest approach: redirect `dashboard#show` to `workshop_briefs_path` and update `DashboardController`.

### Phase 3 — Manual Tests

- [ ] Sign in → redirected to dashboard → see "My Workshops" page (empty state)
- [ ] Click "New Workshop" → form renders with all five fields
- [ ] Duration buttons are mutually exclusive; selecting one highlights it (purple), deselects the others
- [ ] Submit form with all fields → redirected to brief show page; see topic, audience, duration, outcome
- [ ] Brief show page: right column shows "Your agenda will appear here."
- [ ] "Generate Agenda" button is present on the show page
- [ ] Edit a brief → change topic → save → see updated topic on show page
- [ ] Delete a brief → confirm dialog → redirected to index → brief gone
- [ ] Attempt to access another user's brief URL → 404

### Phase 3 — RSpec

**`spec/requests/workshop_briefs_spec.rb`:**
- [ ] `GET /workshop_briefs` returns 200 for signed-in user
- [ ] `GET /workshop_briefs` redirects to sign-in for unauthenticated user
- [ ] `POST /workshop_briefs` with valid params creates a brief and redirects to show
- [ ] `POST /workshop_briefs` with missing topic re-renders form with 422
- [ ] `GET /workshop_briefs/:id` returns 200 for the owning user
- [ ] `GET /workshop_briefs/:id` returns 404 for a different signed-in user (not the owner)
- [ ] `PATCH /workshop_briefs/:id` updates topic and redirects
- [ ] `DELETE /workshop_briefs/:id` destroys the brief and redirects to index

---

## Phase 4 — AI Integration & Agenda Generation

**Goal:** The "Generate Agenda" button calls Gemini, saves a `WorkshopAgenda`, and renders the structured timed agenda. Export to plain text works. All Gemini errors display the shared error partial.

### 4.1 Add redcarpet gem

```ruby
# Gemfile
gem "redcarpet"
```

Run `bundle install`.

### 4.2 AI template seed

In `db/seeds.rb`, add after the existing boilerplate seeds:

```ruby
AiTemplate.find_or_create_by!(name: "flowalong_agenda_v1") do |t|
  t.description = "Generates a timed workshop agenda from a brief. Sections must sum to exactly the specified duration."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 2500
  t.temperature = 0.5
  t.notes = "Lower temperature (0.5) improves timing constraint adherence. Main failure mode: sections do not sum to duration_minutes."

  t.system_prompt = <<~PROMPT
    You are an expert workshop facilitator and instructional designer with 15 years of experience designing and running workshops in corporate, nonprofit, and educational settings.

    You create structured, practical workshop agendas that a first-time facilitator can run without additional preparation. Every agenda you produce is immediately usable.

    Your output format is a timed Markdown agenda. Follow these rules in every response:

    1. The section durations must add up to exactly {{duration_minutes}} minutes. This is a hard constraint. Count the minutes before responding.
    2. Use relative start times from 00:00 (e.g., 00:00, 15:00, 30:00). Do not use clock times.
    3. Each section must be between 5 and 30 minutes. A typical agenda has 4 to 8 sections.
    4. Every agenda must begin with a Welcome and Framing section and end with a Reflection and Next Steps section.
    5. Facilitator notes must be 1 to 3 sentences. Write them as direct instructions to the facilitator, not abstract descriptions.
    6. Each section must include exactly one interactive activity or discussion prompt that fits within the allotted time.
    7. Do not include a standalone "introduction to the topic" section unless the user explicitly requests it. Workshop time is for doing, not presenting.
    8. Use the exact Markdown format shown in the user prompt. Do not deviate from the structure.
    9. Do not add any preamble, summary, or commentary outside the agenda structure itself.
  PROMPT

  t.user_prompt_template = <<~PROMPT
    Create a workshop agenda for the following brief.

    Topic: {{topic}}
    Target Audience: {{audience}}
    Duration: {{duration_minutes}} minutes (hard limit - sections must add up to exactly this number)
    Desired Outcome: {{desired_outcome}}
    {{notes}}

    Format each section using exactly this structure:

    ## [Start Time] - [Section Title] ([Duration] min)

    **Facilitator Note:** [1 to 3 sentences. Direct instruction to the facilitator.]

    **Activity:** [One activity or discussion prompt completable within the allotted time.]

    ---

    Start with a Welcome and Framing section. End with a Reflection and Next Steps section. Confirm that all section durations add up to exactly {{duration_minutes}} minutes before you finish.
  PROMPT
end
```

Run `rails db:seed`.

**Note on `{{notes}}` variable:** Pass an empty string when blank so the placeholder is replaced cleanly. When notes are present, pass `"Additional Notes: #{@brief.notes}"`. This avoids a dangling `{{notes}}` label in the prompt.

### 4.3 WorkshopAgendasController

```ruby
# app/controllers/workshop_agendas_controller.rb
class WorkshopAgendasController < ApplicationController
  before_action :set_brief

  def create
    @brief.workshop_agenda&.destroy

    result = GeminiService.generate(
      template: "flowalong_agenda_v1",
      variables: {
        topic:            @brief.topic,
        audience:         @brief.audience,
        duration_minutes: @brief.duration_minutes,
        desired_outcome:  @brief.desired_outcome,
        notes:            @brief.notes.present? ? "Additional Notes: #{@brief.notes}" : ""
      }
    )

    @agenda = @brief.build_workshop_agenda(
      user:       current_user,
      title:      @brief.topic,
      body:       result,
      gemini_raw: result
    )
    @agenda.save!
    redirect_to workshop_brief_agenda_path(@brief), notice: "Agenda generated."

  rescue GeminiService::BudgetExceededError
    @agenda_error = :budget_exceeded
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::GatekeeperError
    @agenda_error = :gatekeeper_blocked
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::TimeoutError
    @agenda_error = :timeout
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::GeminiError
    @agenda_error = :error
    render "workshop_briefs/show", status: :unprocessable_entity
  end

  def show
    @agenda = current_user.workshop_agendas.find_by!(workshop_brief_id: @brief.id)
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  def destroy
    @agenda = @brief.workshop_agenda
    @agenda&.destroy
    redirect_to @brief, notice: "Agenda deleted."
  end

  def export
    @agenda = current_user.workshop_agendas.find_by!(workshop_brief_id: @brief.id)
    render "workshop_agendas/export", layout: false, content_type: "text/plain"
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  private

  def set_brief
    @brief = current_user.workshop_briefs.find(params[:workshop_brief_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end
end
```

### 4.4 Agenda show view

**`app/views/workshop_agendas/show.html.erb`:**

Page header row:
- `<h1>` with `@agenda.title`
- Audience badge (`badge bg-secondary`) and duration badge
- Buttons: "Regenerate" (`button_to` DELETE to `workshop_brief_agenda_path`), "Export / Print" (link to `export_workshop_brief_agenda_path`), "Back to Brief" (link to `@brief`)

Disclaimer (muted text, no acknowledgment required):
> "Review this agenda before facilitating. AI-generated timing estimates and activities are a starting point, not expert advice. Adjust sections to fit your specific context."

Agenda rendering: The `body` Markdown is parsed into HTML using a `AgendaRenderer` helper or inline with `redcarpet`. Each `## HH:MM - Title (N min)` heading is rendered inside an `.agenda-section-card` with:
- Header bar: `.agenda-time-badge` (time), section title, duration badge
- `**Facilitator Note:**` content in a muted callout
- `**Activity:**` content in `.agenda-activity-box`

The simplest reliable approach: render the full body with `Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(safe_links_only: true)).render(@agenda.body)`, then apply CSS for `.agenda-section-card` via a custom ApplicationHelper or a view helper that post-processes the HTML string.

Alternatively, use a helper method that line-by-line converts the markdown to card-wrapped HTML before passing to the view. Document whichever approach is used; keep it simple.

**Show raw toggle:**
```erb
<div class="mt-4">
  <a class="btn btn-sm btn-outline-secondary" data-bs-toggle="collapse" href="#raw-response">
    Show raw Gemini response
  </a>
  <div class="collapse mt-2" id="raw-response">
    <pre class="bg-dark text-light p-3 rounded" style="font-size: 0.8rem;"><%= @agenda.gemini_raw %></pre>
  </div>
</div>
```

### 4.5 Export view

**`app/views/workshop_agendas/export.text.erb`:**
```
Workshop: <%= @agenda.workshop_brief.topic %> | Audience: <%= @agenda.workshop_brief.audience %> | Duration: <%= @agenda.workshop_brief.duration_minutes %> min | Generated by FlowAlong Demo
================================================================================

<%= @agenda.body %>

--------------------------------------------------------------------------------
AI-generated content can be incorrect. Review this agenda before facilitating.
```

### Phase 4 — Manual Tests

- [ ] On a brief show page, click "Generate Agenda" → wait → redirected to agenda show page
- [ ] Agenda show page: header shows topic, audience badge, duration badge
- [ ] Agenda body renders as section cards (not raw Markdown text)
- [ ] Each card has a purple time badge (e.g. `00:00`), section title, duration badge
- [ ] "Facilitator Note:" content shows in muted callout
- [ ] "Activity:" content shows in purple-tinted box
- [ ] "Show raw Gemini response" toggle collapses/expands the raw text
- [ ] "Export / Print" link returns `text/plain` with the expected header block
- [ ] "Back to Brief" returns to brief show page; right column now shows compact agenda preview
- [ ] "Regenerate" on the agenda page deletes the current agenda; clicking "Generate Agenda" on the brief page creates a new one
- [ ] On brief show page, click "Generate Agenda" while server is offline (or with bad API key) → error partial appears in right column, no crash
- [ ] Admin → AI Templates → `flowalong_agenda_v1` exists with correct model and temperature

### Phase 4 — RSpec

**`spec/requests/workshop_agendas_spec.rb`:**
- [ ] `POST /workshop_briefs/:id/agenda` calls `GeminiService.generate` with `template: "flowalong_agenda_v1"` and correct variable hash (stub via `gemini_returns`)
- [ ] `POST /workshop_briefs/:id/agenda` creates a `WorkshopAgenda` with `body` and `gemini_raw` populated
- [ ] `POST /workshop_briefs/:id/agenda` creates an `LlmRequest` (check `LlmRequest.count` before/after)
- [ ] `POST /workshop_briefs/:id/agenda` when Gemini raises `TimeoutError` — does not create an agenda; response body includes timeout error message
- [ ] `POST /workshop_briefs/:id/agenda` when Gemini raises `BudgetExceededError` — does not create an agenda; response body includes budget error
- [ ] `POST /workshop_briefs/:id/agenda` when called twice — deletes the first agenda and creates a new one (count stays at 1)
- [ ] `GET /workshop_briefs/:id/agenda` returns 200 for the owning user
- [ ] `GET /workshop_briefs/:id/agenda` returns 404 for a different signed-in user
- [ ] `GET /workshop_briefs/:id/agenda` redirects to sign-in for unauthenticated user
- [ ] `GET /workshop_briefs/:id/agenda/export` returns `Content-Type: text/plain` with agenda body content

---

## Phase 5 — Seeds & Dashboard

**Goal:** After `rails db:seed`, the demo user has two briefs: one with a pre-written agenda and one without. The dashboard is the brief index.

### 5.1 Seeded briefs

In `db/seeds.rb`, after the demo user is created, add:

```ruby
demo_user = User.find_by!(email: "demo@example.com")

SAMPLE_AGENDA_BODY = <<~AGENDA
  ## 00:00 - Welcome and Framing (10 min)

  **Facilitator Note:** Welcome participants and introduce yourself briefly. Set the tone: this session is for the team to improve their retro practice, not critique past ones.

  **Activity:** Pair share — each person tells their partner: "One word that describes our last retrospective." Collect words on a whiteboard.

  ---

  ## 10:00 - What Makes a Retro Work (15 min)

  **Facilitator Note:** Share three characteristics of high-impact retrospectives (psychological safety, clear actions, timekeeping). Keep it to bullet points — do not lecture.

  **Activity:** Small groups (3-4 people) discuss: "Which of these three does our team do well, and which do we struggle with most?" Share one insight per group.

  ---

  ## 25:00 - Formats in Practice (20 min)

  **Facilitator Note:** Walk through two retro formats: Start/Stop/Continue and the 4Ls (Liked, Learned, Lacked, Longed For). Demonstrate each with a quick example using the last sprint.

  **Activity:** Each person silently fills in a Start/Stop/Continue template for the last sprint (5 min), then shares one item from each column (10 min).

  ---

  ## 45:00 - Building Our Agreements (20 min)

  **Facilitator Note:** Guide the group to identify patterns across the shared items. The goal is to surface team-specific agreements, not generic best practices.

  **Activity:** Dot voting on themes (3 dots each). The top three themes become the basis for three team agreements. Write agreements in the format: "We will [specific action] in every retro."

  ---

  ## 65:00 - Commitment and Close (10 min)

  **Facilitator Note:** Have the team read the agreements aloud together. Ask each person to share one word about how they feel about the agreements. End on a forward-looking note.

  **Activity:** Each person writes one personal commitment ("I will contribute to our retros by...") on a sticky note and places it on a shared board.

  ---

  ## 75:00 - Reflection and Next Steps (15 min)

  **Facilitator Note:** Close the loop on the session itself. Remind the team that the agreements only work if they hold each other accountable. Identify who will keep time and facilitate the first retro using the new format.

  **Activity:** Fist-to-five vote on each agreement (1 = not confident, 5 = fully committed). For any agreement below 3, spend two minutes addressing the concern.

  ---
AGENDA

brief1 = WorkshopBrief.find_or_create_by!(
  user: demo_user,
  topic: "Running Effective Retrospectives"
) do |b|
  b.audience = "Software engineering teams and their managers"
  b.duration_minutes = 90
  b.desired_outcome = "Teams leave with a specific format they can use immediately and three agreements about how to run their retros going forward"
  b.notes = "Participants may be skeptical about retros. Acknowledge that bad retros are common and this workshop is about fixing that."
end

WorkshopAgenda.find_or_create_by!(workshop_brief: brief1) do |a|
  a.user = demo_user
  a.title = brief1.topic
  a.body = SAMPLE_AGENDA_BODY
  a.gemini_raw = SAMPLE_AGENDA_BODY
end

WorkshopBrief.find_or_create_by!(
  user: demo_user,
  topic: "Introduction to Design Thinking for Product Teams"
) do |b|
  b.audience = "Product managers and UX designers who have heard of design thinking but never run a session"
  b.duration_minutes = 60
  b.desired_outcome = "Each participant completes one rapid problem-framing exercise using the design thinking methodology"
  b.notes = ""
end
```

### 5.2 Dashboard redirect

Update `DashboardController#show`:
```ruby
def show
  redirect_to workshop_briefs_path
end
```

This means signing in routes the user directly to their workshop list. The dashboard view file is no longer needed (can be deleted).

### Phase 5 — Manual Tests

- [ ] Run `rails db:seed` on a clean database — no errors
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Dashboard redirects to `/workshop_briefs`
- [ ] Two briefs appear: "Running Effective Retrospectives" and "Introduction to Design Thinking..."
- [ ] "Running Effective Retrospectives" show page → right column shows compact agenda preview
- [ ] "Introduction to Design Thinking..." show page → right column shows "Your agenda will appear here."
- [ ] Click "Generate Agenda" on the Design Thinking brief (requires live Gemini key) → agenda generates
- [ ] Pre-written agenda for brief 1 renders as section cards (not raw text)
- [ ] Admin → AI Templates → `flowalong_agenda_v1` is present with the correct prompts

### Phase 5 — RSpec

No new RSpec targets for Phase 5. Run the full suite to confirm seeds did not break any existing specs:
```bash
bundle exec rspec
```
All green before proceeding to Phase 6.

---

## Phase 6 — Testing & Polish

**Goal:** Full RSpec suite is green. All manual flows tested. README updated. Code reviewed for any missed edge cases.

### 6.1 Complete the RSpec suite

Ensure all targets from Phases 2–4 are implemented and passing. Add any missing coverage:

- Edge case: `GET /workshop_briefs/:id/agenda` with no agenda → 404
- Edge case: `DELETE /workshop_briefs/:id/agenda` with no agenda → redirect to brief (no crash)
- Cross-user: User B cannot POST to `/workshop_briefs/:id/agenda` for User A's brief

### 6.2 README update

Replace the boilerplate README with the FlowAlong content from Section 11 of the app spec:
- Tagline, one-paragraph description, why I built this, editing the AI prompt, setup instructions
- Keep the environment variables table
- Note the seeded demo credentials

### 6.3 Final UI checks

Run through all manual test checklists from Phases 1–5. Confirm:
- [ ] No raw Markdown visible anywhere in the UI
- [ ] All buttons use btn-accent for primary actions
- [ ] All error states render the shared error partial (no white-screen errors)
- [ ] `Show raw Gemini response` toggle works on the agenda show page
- [ ] Export returns `text/plain` with the correct header and footer
- [ ] Empty state shows correctly when user has no briefs
- [ ] Form validation errors display inline (not just a redirect)
- [ ] Duration button group defaults to nothing selected on new form; persists the selected value on edit/re-render after validation failure

### Phase 6 — Full RSpec Run

```bash
bundle exec rspec --format documentation
```

Expected outcome:
- Zero failures
- Zero real Gemini API calls (all stubbed)
- Coverage spans: model validations, associations, brief CRUD flows, agenda generation success/error paths, access control, export content type

---

## Appendix: Quick Reference

### Named route helpers
```ruby
workshop_briefs_path                             # GET /workshop_briefs
new_workshop_brief_path                          # GET /workshop_briefs/new
workshop_brief_path(@brief)                      # GET /workshop_briefs/:id
edit_workshop_brief_path(@brief)                 # GET /workshop_briefs/:id/edit
workshop_brief_agenda_path(@brief)               # GET/POST/DELETE /workshop_briefs/:id/agenda
export_workshop_brief_agenda_path(@brief)        # GET /workshop_briefs/:id/agenda/export
```

### Gemini stub patterns (in specs)
```ruby
gemini_returns("## 00:00 - Welcome (10 min)\n\n**Facilitator Note:** ...\n\n**Activity:** ...\n\n---")
gemini_raises(GeminiService::TimeoutError)
gemini_raises(GeminiService::BudgetExceededError)
gemini_raises(GeminiService::GatekeeperError)
gemini_raises(GeminiService::GeminiError)
```

### Key decisions
- `turbo_stream.update` not `replace` for all dynamic content
- Stimulus for duration selector only — no plain JS
- `redcarpet` gem for Markdown → HTML
- Gemini model: `gemini-2.5-flash` (not `gemini-2.0-flash`)
- Temperature: `0.5` (lower than default for timing constraint reliability)
- `notes` variable: pass empty string when blank to avoid unresolved `{{notes}}` in prompt
