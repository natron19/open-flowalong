require "rails_helper"

RSpec.describe "WorkshopAgendas", type: :request do
  let(:user)        { create(:user) }
  let(:other)       { create(:user) }
  let(:brief)       { create(:workshop_brief, user: user) }
  let(:other_brief) { create(:workshop_brief, user: other) }

  let(:stub_body) do
    "## 00:00 - Welcome and Framing (10 min)\n\n**Facilitator Note:** Welcome everyone.\n\n**Activity:** Pair share.\n\n---\n\n## 10:00 - Reflection and Next Steps (50 min)\n\n**Facilitator Note:** Close the session.\n\n**Activity:** Dot vote.\n\n---"
  end

  describe "POST /workshop_briefs/:id/agenda" do
    before { sign_in_as(user) }

    context "when Gemini returns a response" do
      before { gemini_returns(stub_body) }

      it "calls GeminiService.generate with the correct template and variables" do
        expect(GeminiService).to receive(:generate).with(
          template: "flowalong_agenda_v1",
          variables: hash_including(
            topic:            brief.topic,
            audience:         brief.audience,
            duration_minutes: brief.duration_minutes,
            desired_outcome:  brief.desired_outcome
          )
        ).and_return(stub_body)

        post workshop_brief_agenda_path(brief)
      end

      it "creates a WorkshopAgenda with body and gemini_raw populated" do
        expect { post workshop_brief_agenda_path(brief) }
          .to change(WorkshopAgenda, :count).by(1)

        agenda = WorkshopAgenda.last
        expect(agenda.body).to eq(stub_body)
        expect(agenda.gemini_raw).to eq(stub_body)
      end

      it "redirects to the agenda show page" do
        post workshop_brief_agenda_path(brief)
        expect(response).to redirect_to(workshop_brief_agenda_path(brief))
      end

      it "replaces an existing agenda instead of creating a second one" do
        create(:workshop_agenda, workshop_brief: brief, user: user)
        expect { post workshop_brief_agenda_path(brief) }
          .not_to change(WorkshopAgenda, :count)
        expect(WorkshopAgenda.last.body).to eq(stub_body)
      end
    end

    context "when Gemini raises TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "does not create an agenda record" do
        expect { post workshop_brief_agenda_path(brief) }
          .not_to change(WorkshopAgenda, :count)
      end

      it "renders an error response" do
        post workshop_brief_agenda_path(brief)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("too long to respond")
      end
    end

    context "when Gemini raises BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "does not create an agenda record" do
        expect { post workshop_brief_agenda_path(brief) }
          .not_to change(WorkshopAgenda, :count)
      end

      it "renders an error response" do
        post workshop_brief_agenda_path(brief)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("daily")
      end
    end

    context "when the brief belongs to another user" do
      it "returns 404" do
        post workshop_brief_agenda_path(other_brief)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /workshop_briefs/:id/agenda" do
    let!(:agenda) { create(:workshop_agenda, workshop_brief: brief, user: user) }

    context "as the owning user" do
      it "returns 200" do
        sign_in_as(user)
        get workshop_brief_agenda_path(brief)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a different signed-in user" do
      it "returns 404" do
        sign_in_as(other)
        get workshop_brief_agenda_path(brief)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get workshop_brief_agenda_path(brief)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when no agenda exists" do
      it "returns 404" do
        sign_in_as(user)
        no_agenda_brief = create(:workshop_brief, user: user)
        get workshop_brief_agenda_path(no_agenda_brief)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /workshop_briefs/:id/agenda" do
    before { sign_in_as(user) }

    context "when an agenda exists" do
      let!(:agenda) { create(:workshop_agenda, workshop_brief: brief, user: user) }

      it "destroys the agenda and redirects to the brief" do
        expect { delete workshop_brief_agenda_path(brief) }
          .to change(WorkshopAgenda, :count).by(-1)
        expect(response).to redirect_to(workshop_brief_path(brief))
      end
    end

    context "when no agenda exists" do
      it "redirects to the brief without error" do
        delete workshop_brief_agenda_path(brief)
        expect(response).to redirect_to(workshop_brief_path(brief))
      end
    end
  end

  describe "GET /workshop_briefs/:id/agenda/export" do
    let!(:agenda) { create(:workshop_agenda, workshop_brief: brief, user: user) }

    it "returns text/plain content type" do
      sign_in_as(user)
      get export_workshop_brief_agenda_path(brief)
      expect(response.content_type).to include("text/plain")
    end

    it "includes the agenda body in the response" do
      sign_in_as(user)
      get export_workshop_brief_agenda_path(brief)
      expect(response.body).to include(agenda.body)
    end

    it "includes the workshop topic in the header line" do
      sign_in_as(user)
      get export_workshop_brief_agenda_path(brief)
      expect(response.body).to include(brief.topic)
    end

    it "redirects to sign in for unauthenticated user" do
      get export_workshop_brief_agenda_path(brief)
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
