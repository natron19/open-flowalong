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
