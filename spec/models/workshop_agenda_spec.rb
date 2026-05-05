require "rails_helper"

RSpec.describe WorkshopAgenda, type: :model do
  let(:brief) { create(:workshop_brief) }

  describe "validations — presence" do
    it "requires a workshop_brief" do
      agenda = WorkshopAgenda.new(user: brief.user, title: "T", body: "content")
      expect(agenda).not_to be_valid
    end

    it "requires a user" do
      agenda = WorkshopAgenda.new(workshop_brief: brief, title: "T", body: "content")
      expect(agenda).not_to be_valid
    end

    it "requires body" do
      agenda = WorkshopAgenda.new(workshop_brief: brief, user: brief.user, title: "T", body: nil)
      expect(agenda).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a workshop_brief" do
      agenda = create(:workshop_agenda, workshop_brief: brief, user: brief.user)
      expect(agenda.workshop_brief).to eq(brief)
    end

    it "belongs to a user" do
      agenda = create(:workshop_agenda, workshop_brief: brief, user: brief.user)
      expect(agenda.user).to eq(brief.user)
    end
  end

  describe "gemini_raw field" do
    it "stores and retrieves the raw Gemini response" do
      raw = "## 00:00 - Welcome (10 min)\n\n**Facilitator Note:** Hi.\n\n**Activity:** Intro."
      agenda = create(:workshop_agenda, gemini_raw: raw)
      expect(agenda.reload.gemini_raw).to eq(raw)
    end

    it "is optional — nil passes validation" do
      agenda = create(:workshop_agenda, gemini_raw: nil)
      expect(agenda).to be_valid
    end
  end
end
