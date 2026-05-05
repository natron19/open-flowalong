# FlowAlong Demo - App Spec

**Version:** 1.0
**Built on:** Open Demo Starter v2.0
**License:** MIT
**Accent Color:** `#8b5cf6` (purple)

---

## 1. App Overview

FlowAlong Demo does one thing: give it a workshop topic, a target audience, a duration (60, 90, or 120 minutes), and a desired outcome, and it returns a complete, timed workshop agenda with named sections, facilitator notes, and one interactive activity per section.

The problem it solves is real: designing a facilitated workshop from scratch requires years of experience most people do not have. You need to know how long activities take, how to open and close a room, how to structure content for engagement rather than lecture, and how to sequence a flow that builds toward a specific outcome. FlowAlong makes that judgment available in a single form submission.

This demo is the template engine at the heart of FlowAlong, a full multi-tenant workshop facilitation platform the author is building. The production version adds team collaboration, facilitator profiles, multi-session programs, participant registration, and run tracking. This demo isolates the single most valuable action in that suite: the agenda generation step that would otherwise take a skilled facilitator one to three hours to produce.

The demo is open source under MIT license, scoped to a single signed-in user, and runs locally. It is not production software. It is a portfolio piece that shows how a structured AI prompt, combined with careful output parsing, can replace a specific expert task in a way that is immediately useful to a non-expert.

---

## 2. Customizations Applied to the Boilerplate

- **App name and branding:** `.env.example` sets `APP_NAME=FlowAlong Demo`, `APP_TAGLINE=Give it a topic and a time limit. Get a complete workshop agenda with activities.`, and `APP_DESCRIPTION=AI-generated workshop agendas for facilitators, educators, and team leads.`
- **Accent color:** `app/assets/stylesheets/_accent.scss` sets `--accent: #8b5cf6` and `--accent-hover: #7c3aed`
- **Navbar links:** Two links added - "My Workshops" (pointing to `workshop_briefs_path`) and "New Workshop" (pointing to `new_workshop_brief_path`). Both are visible to signed-in users only.
- **Home page:** `home/index.html.erb` replaced with a landing pitch specific to FlowAlong Demo: headline, a one-paragraph explanation of the problem, a three-step "how it works" row (Fill in your brief, Generate the agenda, Facilitate with confidence), a sample agenda preview card, and a call-to-action button linking to sign-up.
- **Dashboard page:** `dashboard/show.html.erb` replaced with the user's workshop brief list - a grid of brief summary cards sorted by most recently updated, with a prominent "New Workshop" button at the top. If the user has no briefs, a centered empty state with an illustration placeholder and a "Create your first workshop" call-to-action is shown instead.
- **UX pattern:** Form-then-result with a timed agenda layout. The user fills out a brief form, saves it, then triggers generation. The result is a structured agenda rendered as a series of time-block cards stacked vertically, not a raw text blob.
- **AI templates seeded:** `flowalong_agenda_v1` (full content in Section 7)

---

## 3. Data Model

### WorkshopBrief

The user-authored input record. Stores everything needed to generate an agenda. A brief can exist without an agenda (before generation or after deletion of an agenda).

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key; `belongs_to :user` |
| `topic` | string | Required. **(template variable)** |
| `audience` | string | Required. **(template variable)** |
| `duration_minutes` | integer | Required. One of: 60, 90, 120. **(template variable)** |
| `desired_outcome` | text | Required. **(template variable)** |
| `notes` | text | Optional. Free-form facilitator notes passed to Gemini. **(template variable)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :user`
- `has_one :workshop_agenda, dependent: :destroy`

**Validations:**
- `topic`: presence, maximum 200 characters
- `audience`: presence, maximum 200 characters
- `duration_minutes`: presence, inclusion in `[60, 90, 120]`
- `desired_outcome`: presence, maximum 500 characters
- `notes`: maximum 1000 characters (optional)

---

### WorkshopAgenda

The Gemini-generated output record. One agenda per brief. Stores both the rendered body and the raw Gemini response.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `workshop_brief_id` | uuid | Foreign key; `belongs_to :workshop_brief` |
| `user_id` | uuid | Denormalized FK for direct scoping without join |
| `title` | string | Derived from the brief's topic; set at creation time |
| `body` | text | Parsed markdown agenda text from Gemini |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :workshop_brief`
- `belongs_to :user`

**Validations:**
- `workshop_brief_id`: presence
- `user_id`: presence
- `body`: presence

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| `GET` | `/workshop_briefs` | `workshop_briefs#index` | List all briefs for current user |
| `GET` | `/workshop_briefs/new` | `workshop_briefs#new` | New brief form |
| `POST` | `/workshop_briefs` | `workshop_briefs#create` | Save new brief |
| `GET` | `/workshop_briefs/:id` | `workshop_briefs#show` | Show brief; link to agenda or generate button |
| `GET` | `/workshop_briefs/:id/edit` | `workshop_briefs#edit` | Edit brief form |
| `PATCH` | `/workshop_briefs/:id` | `workshop_briefs#update` | Save edits to brief |
| `DELETE` | `/workshop_briefs/:id` | `workshop_briefs#destroy` | Delete brief and its agenda |
| `POST` | `/workshop_briefs/:workshop_brief_id/agenda` | `workshop_agendas#create` | Trigger Gemini call; save agenda |
| `GET` | `/workshop_briefs/:workshop_brief_id/agenda` | `workshop_agendas#show` | Display generated agenda |
| `DELETE` | `/workshop_briefs/:workshop_brief_id/agenda` | `workshop_agendas#destroy` | Delete agenda (keep brief) |
| `GET` | `/workshop_briefs/:workshop_brief_id/agenda/export` | `workshop_agendas#export` | Render agenda as plain text for copy/print |

All routes require authentication (inherited from `ApplicationController`). All HTML responses; no JSON API routes.

---

## 5. Controllers and Actions

### `WorkshopBriefsController`

Inherits from `ApplicationController`. All queries scoped to `current_user`. Strong parameters permit: `topic`, `audience`, `duration_minutes`, `desired_outcome`, `notes`.

- **`index`:** Loads `current_user.workshop_briefs.order(updated_at: :desc)`. Renders the brief grid (also used as the dashboard replacement).
- **`new`:** Instantiates an empty `WorkshopBrief`. Renders the brief form.
- **`create`:** Saves a new brief from strong params. On success, redirects to the brief's `show` page. On failure, re-renders the form with validation errors.
- **`show`:** Loads the brief and its `workshop_agenda` (if present). Renders the brief summary and either a "Generate Agenda" button (if no agenda exists) or a link to the agenda show page (if it does).
- **`edit`:** Loads the brief. Renders the form pre-filled.
- **`update`:** Saves changes to the brief. On success, redirects to the brief's `show` page. On failure, re-renders the form. If the brief already has an agenda, it is NOT automatically deleted on update; the user must regenerate manually.
- **`destroy`:** Deletes the brief and its associated agenda (via `dependent: :destroy`). Redirects to `workshop_briefs_path` with a flash notice.

---

### `WorkshopAgendasController`

Inherits from `ApplicationController`. All queries scoped to `current_user`. This controller owns the Gemini call.

- **`create`:** Loads the brief via `current_user.workshop_briefs.find(params[:workshop_brief_id])`. Deletes any existing agenda for the brief. Calls `GeminiService.generate(template: "flowalong_agenda_v1", variables: { topic: @brief.topic, audience: @brief.audience, duration_minutes: @brief.duration_minutes, desired_outcome: @brief.desired_outcome, notes: @brief.notes })`. Saves the result as a new `WorkshopAgenda` with `body:` set to the response and `gemini_raw:` set to the raw Gemini string. Redirects to the agenda `show` path on success. Rescues `GeminiService::GeminiError` and its subclasses; renders the shared error partial inline on the brief `show` page with a retry button.
- **`show`:** Loads the agenda via `current_user.workshop_agendas.find_by!(workshop_brief_id: params[:workshop_brief_id])`. Renders the timed agenda view.
- **`destroy`:** Deletes the agenda. Redirects to the parent brief's `show` page with a flash notice.
- **`export`:** Loads the agenda. Renders the `export.text.erb` template with `layout: false`, which outputs the agenda body as plain text with a `Content-Type: text/plain` header. This is the print and copy target.

---

## 6. Views

### `workshop_briefs/index.html.erb`

Renders a grid of `WorkshopBrief` cards (Bootstrap `row`/`col-md-4`). Each card shows: topic, audience, duration badge, and a relative timestamp. Cards link to the brief `show` page. A purple "New Workshop" button is pinned to the top right of the page header. An empty state is rendered if the user has no briefs: centered text, a short explanation, and a "Create your first workshop" button.

---

### `workshop_briefs/new.html.erb` and `workshop_briefs/edit.html.erb`

Both render the `_form.html.erb` partial inside a narrow centered column (`col-md-8 col-lg-6`).

---

### `workshop_briefs/_form.html.erb`

Fields:
- Topic (text input, required, with placeholder "e.g. Psychological Safety in Engineering Teams")
- Target Audience (text input, required, with placeholder "e.g. Engineering managers and team leads")
- Duration (Bootstrap button group; three toggle buttons: "60 min", "90 min", "120 min"; maps to `duration_minutes` integer)
- Desired Outcome (textarea, required, 3 rows, with placeholder "e.g. Participants leave with two specific team agreements they can implement next week")
- Additional Notes (textarea, optional, 2 rows, with helper text "Optional: facilitator experience level, special constraints, or topics to avoid")

Submit button uses the accent color (`btn-accent` or `style="background-color: var(--accent)"`). A cancel link returns to the brief index.

---

### `workshop_briefs/show.html.erb`

Two-panel layout (Bootstrap row):

- **Left column (`col-md-4`):** Brief summary card. Lists topic, audience, duration, desired outcome, and notes. Edit and delete links. If no agenda exists, a prominent purple "Generate Agenda" button is rendered as a `button_to` POSTing to `workshop_agenda_path`. A small disclaimer note appears below the button: "Agenda generation uses AI. Results may vary. Review before facilitating."
- **Right column (`col-md-8`):** If an agenda exists, shows a compact preview (first section only, with a "View Full Agenda" link). If no agenda exists, shows a placeholder card with light text "Your agenda will appear here."

If a Gemini error was rescued in `WorkshopAgendasController#create`, the error partial is rendered at the top of the right column via an instance variable set in the controller before rendering the brief show template.

---

### `workshop_agendas/show.html.erb`

Page header: workshop topic as the `<h1>`, audience and duration as subtitle badges. Buttons in the header row: "Regenerate" (button_to to `workshop_agenda_path`, method DELETE then redirect to show for simplicity; or a separate regenerate action), "Export / Print" (link to `export_workshop_brief_agenda_path`), and "Back to Brief" (link to `workshop_brief_path`).

**Agenda rendering:** The `body` field is parsed from Markdown into HTML using the `redcarpet` gem (added as a dependency). Each `## [Time] - [Section Title] ([Duration] min)` Markdown heading becomes a styled section card:
- Section header bar: time badge (purple), section title, duration badge
- Body: facilitator note in a muted callout block
- Activity in a highlighted box with a slight purple tint

The parser uses a simple line-by-line approach. Headings that match the `## HH:MM - Title (N min)` pattern get the card treatment; everything else renders as normal HTML.

**Show raw response toggle:** Below all section cards, a Bootstrap `collapse` block labeled "Show raw Gemini response" reveals the `gemini_raw` field content in a `<pre>` block with a monospace font and a dark background. This toggle is required by the boilerplate's UX expectation.

---

### `workshop_agendas/export.text.erb`

Plain-text rendering of the agenda `body` with no HTML. Rendered with `layout: false`. Used for clipboard copy and print. Includes a header block: "Workshop: [topic] | Audience: [audience] | Duration: [duration] min | Generated by FlowAlong Demo". The footer includes the AI disclaimer.

---

### `shared/_gemini_error.html.erb`

Inherited from the boilerplate. Renders an inline Bootstrap alert with the appropriate message for each `GeminiError` subclass (budget exceeded, gatekeeper blocked, timeout, general error) and a retry button.

---

## 7. AI Templates and Gemini Integration

### Template: `flowalong_agenda_v1`

**Description:** Generates a timed workshop agenda from a brief. Sections must sum to exactly the specified duration.

---

**`system_prompt`:**

```
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
```

---

**`user_prompt_template`:**

```
Create a workshop agenda for the following brief.

Topic: {{topic}}
Target Audience: {{audience}}
Duration: {{duration_minutes}} minutes (hard limit - sections must add up to exactly this number)
Desired Outcome: {{desired_outcome}}
{{#if notes}}Additional Notes: {{notes}}{{/if}}

Format each section using exactly this structure:

## [Start Time] - [Section Title] ([Duration] min)

**Facilitator Note:** [1 to 3 sentences. Direct instruction to the facilitator.]

**Activity:** [One activity or discussion prompt completable within the allotted time.]

---

Start with a Welcome and Framing section. End with a Reflection and Next Steps section. Confirm that all section durations add up to exactly {{duration_minutes}} minutes before you finish.
```

---

**Variables consumed:**

- `{{topic}}` - `WorkshopBrief#topic`
- `{{audience}}` - `WorkshopBrief#audience`
- `{{duration_minutes}}` - `WorkshopBrief#duration_minutes` (integer: 60, 90, or 120)
- `{{desired_outcome}}` - `WorkshopBrief#desired_outcome`
- `{{notes}}` - `WorkshopBrief#notes` (optional; passed as empty string if blank)

---

**`model`:** `gemini-2.0-flash` (default). This template does not justify a more capable model; the task is structured formatting, not complex reasoning.

**`max_output_tokens`:** `2500`. A full 120-minute agenda with 8 sections, facilitator notes, and activities reaches approximately 1800 to 2200 tokens. 2500 gives headroom without wasteful cap.

**`temperature`:** `0.5`. Lower than the boilerplate default of 0.7. Workshop agendas require structural reliability (timing constraints, section counts) more than creative variance. Lower temperature reduces the risk of the model inventing exotic formats or ignoring the timing rules. If output feels repetitive, raise to 0.6 and test.

**`notes` (author's notes):**

The most common failure mode is sections summing to the wrong total (usually 65 or 85 minutes for a 60 or 90-minute brief). The system prompt includes an explicit self-check instruction ("Confirm that all section durations add up to exactly {{duration_minutes}} minutes before you finish"). If this still fails, try adding a post-output check in `WorkshopAgendasController#create` that parses the returned section durations and alerts the user if they do not sum correctly, suggesting regeneration.

The second failure mode is an "introduction" section that eats 15-20 minutes explaining the topic. The system prompt's rule 7 addresses this directly. If it persists, strengthen the rule by adding "This is the most common mistake facilitators make and it kills energy in the room."

Temperature at 0.5 may occasionally produce bland activity suggestions. If workshop owners report activities feeling generic, raise temperature to 0.6 and run 10 test generations to confirm timing reliability holds.

---

**Where it's called:** `WorkshopAgendasController#create`

```ruby
result = GeminiService.generate(
  template: "flowalong_agenda_v1",
  variables: {
    topic: @brief.topic,
    audience: @brief.audience,
    duration_minutes: @brief.duration_minutes,
    desired_outcome: @brief.desired_outcome,
    notes: @brief.notes.presence || ""
  }
)
```

---

**Expected output format:** Markdown. Structure:

```markdown
## 00:00 - Welcome and Framing (10 min)

**Facilitator Note:** Welcome participants and introduce yourself briefly...

**Activity:** Pair share: each person tells their partner one word...

---

## 10:00 - [Section Title] (15 min)

...
```

**How the response is parsed and rendered:** The `body` field stores the raw Markdown string returned by Gemini. The `WorkshopAgendasController#show` view parses this with `redcarpet` into HTML for display, and applies additional CSS classes to section headers matching the `## HH:MM` pattern for the card layout. No further transformation is done before storage; `gemini_raw` stores the same string as an audit copy.

**Which field stores the raw response:** `WorkshopAgenda#gemini_raw`

---

## 8. AI Safety Considerations (Specific to This App)

**Content sensitivity:** Workshop design is low-stakes. The input is a professional topic, an audience description, a duration, and a desired outcome. There is no mental health content, medical advice, legal guidance, or personal information involved in a standard usage path. The most sensitive plausible input is a workshop on topics like conflict resolution or giving difficult feedback, where a poorly structured agenda could lead to a difficult facilitation experience. This is a planning tool, not a direct participant-facing tool.

**Consequential outputs:** A facilitator could run a Gemini-generated agenda with real participants and the agenda could be poorly structured, have timing errors, include an awkward activity, or miss the desired outcome. The worst case is a wasted workshop hour, not harm to participants. The tool positions itself explicitly as a starting point, not a finished product.

**Domain accuracy requirements:** Workshop facilitation has established best practices (opening circles, energy management, closing rituals, time buffers) that Gemini may not consistently apply. The system prompt enforces the structural minimum (welcome, close, timed sections) but does not enforce advanced facilitation theory. The disclaimer on the brief show page and in the export footer makes explicit that the output should be reviewed before use.

**App-specific disclaimer copy:** In addition to the boilerplate's footer note ("AI-generated content can be incorrect. Verify before acting."), add the following on the agenda show page, directly below the page header:

> "Review this agenda before facilitating. AI-generated timing estimates and activities are a starting point, not expert advice. Adjust sections to fit your specific context."

This disclaimer appears in non-intrusive muted text and does not require acknowledgment.

**Tightened settings:** Temperature is lowered to 0.5 (from the default 0.7) to improve timing constraint adherence. No tightening to the per-user daily cap or gatekeeper is needed; workshop agenda generation is not an abuse vector that warrants restrictions below the boilerplate default of 50 calls per day.

**What this demo deliberately does NOT do (for safety reasons):**
- Does not validate that the generated sections actually sum to the stated duration (detecting this would require parsing the output and surfacing a warning; a useful future addition but out of scope for the demo).
- Does not evaluate whether the generated activities are appropriate for the stated audience (e.g., a debate-style activity for a group of strangers could backfire). This judgment belongs to the facilitator.
- Does not save facilitator identity or participant data. There is no participant list, no run history, and no personal information beyond the user's account.

---

## 9. RSpec Outline

### `spec/models/workshop_brief_spec.rb`

- Validates presence of `topic`, `audience`, `duration_minutes`, `desired_outcome`
- Validates that `duration_minutes` must be one of 60, 90, 120
- Validates maximum length of `topic` (200 chars), `audience` (200 chars), `desired_outcome` (500 chars), `notes` (1000 chars)
- Has one `workshop_agenda` that is destroyed when the brief is destroyed
- Belongs to a `user`

### `spec/models/workshop_agenda_spec.rb`

- Validates presence of `workshop_brief_id`, `user_id`, `body`
- Belongs to a `workshop_brief`
- Belongs to a `user`
- `gemini_raw` field is stored and retrievable

### `spec/requests/workshop_briefs_spec.rb`

- `GET /workshop_briefs` returns 200 for signed-in user; redirects to sign-in for unauthenticated user
- `POST /workshop_briefs` creates a brief and redirects to brief show page on valid params
- `POST /workshop_briefs` re-renders the form on invalid params (missing topic)
- A signed-in user cannot view another user's brief (returns 404)
- `DELETE /workshop_briefs/:id` destroys the brief and redirects to the index

### `spec/requests/workshop_agendas_spec.rb`

- `POST /workshop_briefs/:id/agenda` calls `GeminiService.generate` with the correct template name and variable hash (stubbed via the boilerplate test double)
- `POST /workshop_briefs/:id/agenda` creates a `WorkshopAgenda` record with `body` and `gemini_raw` populated
- `POST /workshop_briefs/:id/agenda` creates an `LlmRequest` record (verified by checking `LlmRequest.count` before and after)
- `POST /workshop_briefs/:id/agenda` when Gemini raises `GeminiService::TimeoutError`, does not create an agenda record and renders the error partial (check response body for error message)
- `GET /workshop_briefs/:id/agenda` returns 200 for the owning user
- A signed-in user cannot view another user's agenda (returns 404)
- `GET /workshop_briefs/:id/agenda/export` returns `text/plain` content type

---

## 10. Seed Data

### AiTemplate seeds

`db/seeds.rb` creates the following record (confirming the full content from Section 7):

```ruby
AiTemplate.find_or_create_by!(name: "flowalong_agenda_v1") do |t|
  t.description = "Generates a timed workshop agenda from a brief. Sections must sum to exactly the specified duration."
  t.system_prompt = <<~PROMPT
    [full system_prompt text from Section 7]
  PROMPT
  t.user_prompt_template = <<~PROMPT
    [full user_prompt_template text from Section 7]
  PROMPT
  t.model = "gemini-2.0-flash"
  t.max_output_tokens = 2500
  t.temperature = 0.5
  t.notes = "Lower temperature (0.5) improves timing constraint adherence. Main failure mode: sections do not sum to duration_minutes. See spec Section 7 for debugging guidance."
end
```

### Domain seeds

Two sample `WorkshopBrief` records seeded for the demo user, with a pre-generated `WorkshopAgenda` for the first brief so the app shows real output immediately after `bin/setup`:

**Brief 1 (with agenda):**
- `topic`: "Running Effective Retrospectives"
- `audience`: "Software engineering teams and their managers"
- `duration_minutes`: 90
- `desired_outcome`: "Teams leave with a specific format they can use immediately and three agreements about how to run their retros going forward"
- `notes`: "Participants may be skeptical about retros. Acknowledge that bad retros are common and this workshop is about fixing that."

The seeded agenda for Brief 1 is stored as a pre-written `body` string (not generated live at seed time, to avoid requiring a Gemini key during setup). The `gemini_raw` field stores the same string. A seed comment notes: "This is a hand-authored sample agenda; replace by running the app and generating a real one."

**Brief 2 (no agenda):**
- `topic`: "Introduction to Design Thinking for Product Teams"
- `audience`: "Product managers and UX designers who have heard of design thinking but never run a session"
- `duration_minutes`: 60
- `desired_outcome`: "Each participant completes one rapid problem-framing exercise using the design thinking methodology"
- `notes`: ""

Brief 2 has no agenda so the demo user can experience the generation flow immediately after setup.

---

## 11. README Additions

### FlowAlong Demo

**Tagline:** Give it a topic and a time limit. Get a complete workshop agenda with activities.

FlowAlong Demo is a single-purpose Rails 8 app that turns a workshop brief (topic, audience, duration, desired outcome) into a structured, timed agenda using Google Gemini. Fill in the four-field brief form, click "Generate Agenda", and get a session plan with named sections, facilitator notes, and one activity per section - ready to use or adapt.

This is the agenda generation engine at the core of FlowAlong, a multi-tenant workshop facilitation platform currently in development. The full platform adds facilitator profiles, multi-session programs, participant registration, and run history with post-session notes. FlowAlong Demo isolates the single most time-consuming step in workshop design and makes it available as a clean, open source tool.

The production app is at [https://flowalong.app](https://flowalong.app) (placeholder).

**[Screenshot placeholder - a generated 90-minute agenda showing section cards with time badges, facilitator notes, and activities]**

### Why I built this

Designing a workshop is hard. You need to know how long icebreakers actually take, how to pace energy across 90 minutes, how to write facilitator notes that a nervous first-time facilitator can actually follow, and how to make sections flow toward a specific outcome rather than just covering content. Most people who run workshops learned these skills the hard way, by running bad ones.

I am building FlowAlong to bring facilitation structure to people who do not have a background in learning design. This demo is the simplest possible version of that idea: one form, one AI call, one structured output. The full app will layer in templates, run tracking, and team features, but this is where it starts.

This repo is open source under MIT license. Clone it, run it locally, tune the prompt in `/admin/ai_templates`, and adapt it to whatever workshop problems you are solving.

### Editing the AI prompt

The agenda generation prompt is stored as data, not code. After `bin/setup`, sign in as `demo@example.com` (password: `password123`) and navigate to `/admin/ai_templates`. Select `flowalong_agenda_v1`, edit the system prompt or user prompt template, enter sample variable values in the test panel, click Test to see Gemini's response inline, then Save to persist the changes. No server restart required.

### Setup

No additional setup steps beyond the standard `bin/setup` are required. Set `GEMINI_API_KEY` in `.env` before running the app. The seeded Brief 1 has a pre-written sample agenda so you can see the output format immediately. To generate a real Gemini-powered agenda, click "Generate Agenda" on Brief 2 after starting the server.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

**Layout pattern:** Form-heavy for brief creation; card-based for the brief index; timed agenda cards stacked vertically for the agenda show page. No kanban, no wizard, no table-based list.

**Accent color application:**
- Primary buttons (`btn` styled with `background-color: var(--accent)` and `border-color: var(--accent)`) for: "Generate Agenda", "Save Brief", "New Workshop", and "Regenerate"
- Active navbar link state: `color: var(--accent)` on the current page's nav link
- Time badge on each agenda section card: `background-color: var(--accent)` with white text
- Duration toggle button group: the selected option uses `background-color: var(--accent)` via an active state class set by a minimal Stimulus controller (one controller, `duration-selector`, that adds the active class on click and updates the hidden integer input)
- Focus rings on inputs: `outline-color: var(--accent)` via CSS custom property override in `_accent.scss`

**Custom CSS added beyond the boilerplate:**

`_accent.scss` overrides:
```scss
:root {
  --accent: #8b5cf6;
  --accent-hover: #7c3aed;
}

.btn-accent {
  background-color: var(--accent);
  border-color: var(--accent);
  color: #fff;

  &:hover {
    background-color: var(--accent-hover);
    border-color: var(--accent-hover);
    color: #fff;
  }
}
```

`_agenda.scss` (new file, minimal):
```scss
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

No other custom CSS is added. Everything else uses Bootstrap 5 utility classes (`text-muted`, `card`, `badge`, `collapse`, `row`, `col-md-*`, etc.) from the dark mode theme already in the boilerplate.

---

*v1.0 - FlowAlong Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
