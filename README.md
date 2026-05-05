# FlowAlong Demo

> Give it a topic and a time limit. Get a complete workshop agenda with activities.

FlowAlong Demo is a single-purpose Rails 8 app that turns a workshop brief (topic, audience, duration, desired outcome) into a structured, timed agenda using Google Gemini. Fill in the four-field brief form, click "Generate Agenda", and get a session plan with named sections, facilitator notes, and one activity per section — ready to use or adapt.

This is the agenda generation engine at the core of FlowAlong, a multi-tenant workshop facilitation platform currently in development. The full platform adds facilitator profiles, multi-session programs, participant registration, and run history with post-session notes. FlowAlong Demo isolates the single most time-consuming step in workshop design and makes it available as a clean, open source tool.

## Why I built this

Designing a workshop is hard. You need to know how long icebreakers actually take, how to pace energy across 90 minutes, how to write facilitator notes that a nervous first-time facilitator can actually follow, and how to make sections flow toward a specific outcome rather than just covering content. Most people who run workshops learned these skills the hard way, by running bad ones.

I am building FlowAlong to bring facilitation structure to people who do not have a background in learning design. This demo is the simplest possible version of that idea: one form, one AI call, one structured output. The full app will layer in templates, run tracking, and team features, but this is where it starts.

This repo is open source under MIT license. Clone it, run it locally, tune the prompt in `/admin/ai_templates`, and adapt it to whatever workshop problems you are solving.

## Setup

```bash
git clone https://github.com/natron19/open-flowalong
cd open-flowalong
bin/setup
```

Add your Gemini API key to `.env`:
```
GEMINI_API_KEY=your_key_here
```

Get a free key at https://aistudio.google.com/app/apikey

```bash
bin/rails server
```

Visit http://localhost:3000 and sign in with `demo@example.com` / `password123`.

The seeded account includes a pre-written sample agenda so you can see the output format immediately. To generate a real Gemini-powered agenda, click "Generate Agenda" on the second brief.

## Editing the AI prompt

The agenda generation prompt is stored as data, not code. After `bin/setup`, sign in as `demo@example.com` (password: `password123`) and navigate to `/admin/ai_templates`. Select `flowalong_agenda_v1`, edit the system prompt or user prompt template, enter sample variable values in the test panel, click Test to see Gemini's response inline, then Save to persist the changes. No server restart required.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"Open Demo Starter"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini 2.5 Flash via `faraday` (direct REST) |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## AI Safety

- Per-user daily call cap (default: 50/day, configurable via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate in `/admin/llm_requests`
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page

## Demo Credentials

| Email | Password | Role |
|---|---|---|
| `demo@example.com` | `password123` | Admin |

## License

MIT — see [LICENSE](LICENSE)
