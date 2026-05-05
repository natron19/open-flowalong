FactoryBot.define do
  factory :workshop_agenda do
    workshop_brief
    user       { workshop_brief.user }
    title      { workshop_brief.topic }
    body       { "## 00:00 - Welcome and Framing (10 min)\n\n**Facilitator Note:** Welcome participants.\n\n**Activity:** Pair share.\n\n---" }
    gemini_raw { body }
  end
end
