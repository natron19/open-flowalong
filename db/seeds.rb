# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

# Placeholder demo template — each demo app replaces this
AiTemplate.find_or_create_by!(name: "demo_placeholder_v1") do |t|
  t.description          = "Starter template. Replace with your demo's actual prompt."
  t.system_prompt        = "You are a helpful assistant."
  t.user_prompt_template = "Please help me with: {{request}}"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 2000
  t.temperature          = 0.7
  t.notes                = "Starter template. Replace this in your demo app's seeds.rb."
end

puts "Seeded: demo_placeholder_v1 AI template"

# FlowAlong agenda generation template
AiTemplate.find_or_create_by!(name: "flowalong_agenda_v1") do |t|
  t.description = "Generates a timed workshop agenda from a brief. Sections must sum to exactly the specified duration."
  t.model = "gemini-2.5-flash"
  t.max_output_tokens = 2500
  t.temperature = 0.5
  t.notes = "Lower temperature (0.5) improves timing constraint adherence. Main failure mode: sections do not sum to duration_minutes. The {{notes}} variable should be passed as an empty string when blank, or as 'Additional Notes: <text>' when present."

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

puts "Seeded: flowalong_agenda_v1 AI template"

# ── Sample Workshop Briefs ──────────────────────────────────────────────────────
demo_user = User.find_by!(email: "demo@example.com")

# Hand-authored sample agenda — stored without a live Gemini call so bin/setup
# works without a valid API key.
SAMPLE_AGENDA_BODY = <<~AGENDA
  ## 00:00 - Welcome and Framing (10 min)

  **Facilitator Note:** Welcome participants and introduce yourself briefly. Set the tone: this session is for the team to improve their retro practice, not to critique past ones.

  **Activity:** Pair share — each person tells their partner one word that describes their last retrospective. Collect words on a shared whiteboard.

  ---

  ## 10:00 - What Makes a Retro Work (15 min)

  **Facilitator Note:** Share three characteristics of high-impact retrospectives: psychological safety, clear actions, and timekeeping. Keep it to bullet points — do not lecture.

  **Activity:** Small groups (3-4 people) discuss: "Which of these three does our team do well, and which do we struggle with most?" Each group shares one insight.

  ---

  ## 25:00 - Formats in Practice (20 min)

  **Facilitator Note:** Walk through two retro formats — Start/Stop/Continue and the 4Ls (Liked, Learned, Lacked, Longed For). Demonstrate each with a quick example using the last sprint.

  **Activity:** Each person silently fills in a Start/Stop/Continue template for the last sprint (5 min), then shares one item from each column (10 min total).

  ---

  ## 45:00 - Building Our Agreements (20 min)

  **Facilitator Note:** Guide the group to identify patterns across the shared items. The goal is to surface team-specific agreements, not generic best practices.

  **Activity:** Dot voting on themes (3 dots each). The top three themes become the basis for three team agreements. Write agreements in the format: "We will [specific action] in every retro."

  ---

  ## 65:00 - Commitment and Close (10 min)

  **Facilitator Note:** Have the team read the agreements aloud together. Ask each person to share one word about how they feel about the agreements. End on a forward-looking note.

  **Activity:** Each person writes one personal commitment ("I will contribute to our retros by...") on a sticky note and places it on the shared board.

  ---

  ## 75:00 - Reflection and Next Steps (15 min)

  **Facilitator Note:** Close the loop on the session itself. Identify who will keep time and facilitate the first retro using the new format. Remind the team that the agreements only work if they hold each other accountable.

  **Activity:** Fist-to-five vote on each agreement (1 = not confident, 5 = fully committed). For any agreement below 3, spend two minutes addressing the concern.

  ---
AGENDA

brief1 = WorkshopBrief.find_or_create_by!(user: demo_user, topic: "Running Effective Retrospectives") do |b|
  b.audience         = "Software engineering teams and their managers"
  b.duration_minutes = 90
  b.desired_outcome  = "Teams leave with a specific format they can use immediately and three agreements about how to run their retros going forward"
  b.notes            = "Participants may be skeptical about retros. Acknowledge that bad retros are common and this workshop is about fixing that."
end

WorkshopAgenda.find_or_create_by!(workshop_brief: brief1) do |a|
  a.user       = demo_user
  a.title      = brief1.topic
  a.body       = SAMPLE_AGENDA_BODY
  a.gemini_raw = SAMPLE_AGENDA_BODY
end

puts "Seeded: Running Effective Retrospectives brief + sample agenda"

WorkshopBrief.find_or_create_by!(user: demo_user, topic: "Introduction to Design Thinking for Product Teams") do |b|
  b.audience         = "Product managers and UX designers who have heard of design thinking but never run a session"
  b.duration_minutes = 60
  b.desired_outcome  = "Each participant completes one rapid problem-framing exercise using the design thinking methodology"
  b.notes            = ""
end

puts "Seeded: Introduction to Design Thinking brief (no agenda — generate one to try the flow)"
