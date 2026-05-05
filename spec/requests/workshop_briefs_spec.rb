require "rails_helper"

RSpec.describe "WorkshopBriefs", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:brief) { create(:workshop_brief, user: user) }

  let(:valid_params) do
    {
      workshop_brief: {
        topic: "Giving Feedback Effectively",
        audience: "New managers",
        duration_minutes: 60,
        desired_outcome: "Participants practice the SBI framework",
        notes: ""
      }
    }
  end

  let(:invalid_params) do
    { workshop_brief: { topic: "", audience: "New managers", duration_minutes: 60, desired_outcome: "x" } }
  end

  describe "GET /workshop_briefs" do
    context "when signed in" do
      it "returns 200" do
        sign_in_as(user)
        get workshop_briefs_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get workshop_briefs_path
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "GET /workshop_briefs/new" do
    it "returns 200 for signed-in user" do
      sign_in_as(user)
      get new_workshop_brief_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to sign in for unauthenticated user" do
      get new_workshop_brief_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "POST /workshop_briefs" do
    before { sign_in_as(user) }

    context "with valid params" do
      it "creates a brief and redirects to its show page" do
        expect { post workshop_briefs_path, params: valid_params }
          .to change(WorkshopBrief, :count).by(1)
        expect(response).to redirect_to(workshop_brief_path(WorkshopBrief.last))
      end
    end

    context "with missing topic" do
      it "re-renders the form with 422" do
        post workshop_briefs_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /workshop_briefs/:id" do
    context "as the owning user" do
      it "returns 200" do
        sign_in_as(user)
        get workshop_brief_path(brief)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a different signed-in user" do
      it "returns 404" do
        sign_in_as(other)
        get workshop_brief_path(brief)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get workshop_brief_path(brief)
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe "PATCH /workshop_briefs/:id" do
    before { sign_in_as(user) }

    it "updates the brief and redirects to show" do
      patch workshop_brief_path(brief), params: { workshop_brief: { topic: "New Topic" } }
      expect(response).to redirect_to(workshop_brief_path(brief))
      expect(brief.reload.topic).to eq("New Topic")
    end

    it "re-renders edit with 422 on invalid params" do
      patch workshop_brief_path(brief), params: { workshop_brief: { topic: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /workshop_briefs/:id" do
    before { sign_in_as(user) }

    it "destroys the brief and redirects to index" do
      brief_to_delete = create(:workshop_brief, user: user)
      expect { delete workshop_brief_path(brief_to_delete) }
        .to change(WorkshopBrief, :count).by(-1)
      expect(response).to redirect_to(workshop_briefs_path)
    end
  end
end
