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

## Responsible AI

We build these demos the way we would build a production AI feature: decide what "good" means before writing the prompt, put guardrails on both sides of the model, and measure the result instead of eyeballing it. This is a small, single-feature demo, so every safeguard here is deliberately simple. Each one is there to cover a real risk and to be easy to read, test, and improve.

### Guardrails

**Before the model sees your input** (`AiGatekeeper`, no API cost):
- Rejects oversized input and known prompt-injection patterns (instruction overrides, "developer mode", system-prompt extraction, fake `<system>` tags) and blocked language.

**Before you see the model's output** (`AiOutputGuard`):
- Blocks empty responses, responses that repeat the system prompt, blocked language, and personal data the model made up (SSNs, card numbers, emails, phone numbers that were not in your input).

**Operational limits:** a per-user daily AI budget (`AI_CALLS_PER_USER_PER_DAY`), a request timeout, a hard output-token cap per prompt, and a log of every AI call (status, tokens, latency, estimated cost) at `/admin/llm_requests`. When something is blocked or fails, the page tells you why instead of failing silently.

### How we evaluate it

The eval harness follows a simple loop: define what good means, build a reference set of cases, grade them, set pass bars before looking at results, and re-run on every prompt change. Details are in [`docs/ai-evals.md`](docs/ai-evals.md).

| What we check | How | Run it |
|---|---|---|
| Guardrails catch attacks and leave normal input alone | Offline attack and look-alike suite, no API cost | `bin/rails evals:guardrails` |
| Output has the right shape | Code checks: required fields, counts, lengths | `bin/rails evals:run` |
| Output is actually good | An LLM judge scores each case 1–5 against a written rubric, after first proving it agrees with human-labeled examples | `bin/rails evals:run` |
| Latency, cost, and error rate | Read from the request log for each eval case | `bin/rails evals:run` |
| The real feature works in a browser | Headless Chrome walks the main AI feature, plus a blocked-input journey | Maintainer's fleet test harness, run before releases |

This app has 7 eval cases (typical, edge-case, adversarial, and benign look-alike inputs). The judge scores it on:

- **Useful:** Every activity fits the stated audience and visibly moves the group toward the desired outcome.
- **Useful:** Timing is realistic. Each activity can actually be completed in its allotted minutes, and the agenda favors doing over presenting.
- **Accurate:** The agenda is grounded in the brief and honors any additional notes the author gave.

**Current status (October 2026):** the guardrail suite passes: 11/11 input attacks and 7/7 output attacks blocked, with no false positives (12/12 and 6/6 benign cases allowed). Live-model eval baselines are being run next and will be published here. Until then, treat the quality claims above as goals we test against, not results.

### What this demo does and doesn't do

**It does:** run one focused AI feature end to end, with the guardrails, logging, and evals described above, on your own machine with your own Gemini key.

**It doesn't (yet):**
- Guarantee correct output. Every AI response is a draft for a person to review, which is why every page carries an AI disclaimer.
- Catch every attack. The input and output guards are pattern-based. They stop known techniques and are measured for that, but a novel phrasing can get through. That is why the output guard and the evals exist as a second layer.
- Scrub personal data from what you type. Don't paste anything sensitive into a local demo.
- Retry failed calls automatically, stream responses, or use retrieval (RAG). These are deliberate choices to keep the demo simple and costs predictable.

## Contributing and feedback

This project is open source and we want it to be useful to real people. Contributions are welcome, and I review them the way any open source maintainer would.

- **Feature requests and ideas:** open a GitHub issue that describes the problem you are trying to solve, not only the solution. Examples of the outputs you wish you got are especially helpful.
- **Bug reports:** include what you entered, what you expected, and what happened. For AI quality problems, the output itself is the most useful evidence.
- **Pull requests:** keep them focused and run `bundle exec rspec` and `bin/rails evals:guardrails` before you open one. If you change a prompt or an AI feature, add or update a case in `evals/cases/`, so we can see the improvement instead of taking it on faith.
- **Reviews:** I read every issue and review every pull request personally. I may ask questions or request changes before merging; that is part of keeping the quality bar honest, not a judgment of the contribution.
- **Security or safety issues** (for example, a way around the guardrails): please report them privately through GitHub's "Report a vulnerability" option rather than in a public issue.

## Demo Credentials

| Email | Password | Role |
|---|---|---|
| `demo@example.com` | `password123` | Admin |

## License

MIT — see [LICENSE](LICENSE)
