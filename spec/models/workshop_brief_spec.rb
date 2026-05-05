require "rails_helper"

RSpec.describe WorkshopBrief, type: :model do
  describe "associations" do
    it "is invalid without a user" do
      expect(build(:workshop_brief, user: nil)).not_to be_valid
    end

    it "has one workshop_agenda" do
      brief = create(:workshop_brief)
      agenda = create(:workshop_agenda, workshop_brief: brief, user: brief.user)
      expect(brief.workshop_agenda).to eq(agenda)
    end
  end

  describe "validations — presence" do
    it "requires topic" do
      expect(build(:workshop_brief, topic: nil)).not_to be_valid
    end

    it "requires audience" do
      expect(build(:workshop_brief, audience: nil)).not_to be_valid
    end

    it "requires duration_minutes" do
      expect(build(:workshop_brief, duration_minutes: nil)).not_to be_valid
    end

    it "requires desired_outcome" do
      expect(build(:workshop_brief, desired_outcome: nil)).not_to be_valid
    end
  end

  describe "validations — length" do
    it "limits topic to 200 chars" do
      expect(build(:workshop_brief, topic: "a" * 201)).not_to be_valid
    end

    it "accepts topic at exactly 200 chars" do
      expect(build(:workshop_brief, topic: "a" * 200)).to be_valid
    end

    it "limits audience to 200 chars" do
      expect(build(:workshop_brief, audience: "a" * 201)).not_to be_valid
    end

    it "limits desired_outcome to 500 chars" do
      expect(build(:workshop_brief, desired_outcome: "a" * 501)).not_to be_valid
    end

    it "limits notes to 1000 chars" do
      expect(build(:workshop_brief, notes: "a" * 1001)).not_to be_valid
    end
  end

  describe "validations — duration_minutes" do
    it "accepts 60, 90, and 120" do
      [60, 90, 120].each do |valid|
        brief = build(:workshop_brief, duration_minutes: valid)
        expect(brief).to be_valid, "Expected #{valid} to be valid"
      end
    end

    it "rejects values outside [60, 90, 120]" do
      [45, 75, 180, 0, nil].each do |invalid|
        brief = build(:workshop_brief, duration_minutes: invalid)
        expect(brief).not_to be_valid, "Expected #{invalid.inspect} to be invalid"
      end
    end
  end

  describe "notes" do
    it "is optional — blank passes validation" do
      brief = build(:workshop_brief, notes: "")
      expect(brief).to be_valid
    end

    it "is optional — nil passes validation" do
      brief = build(:workshop_brief, notes: nil)
      expect(brief).to be_valid
    end
  end

  describe "dependent destroy" do
    it "destroys associated workshop_agenda when brief is destroyed" do
      brief = create(:workshop_brief)
      create(:workshop_agenda, workshop_brief: brief, user: brief.user)
      expect { brief.destroy }.to change(WorkshopAgenda, :count).by(-1)
    end
  end
end
