class WorkshopAgendasController < ApplicationController
  before_action :set_brief

  def create
    @brief.workshop_agenda&.destroy

    result = GeminiService.generate(
      template: "flowalong_agenda_v1",
      variables: {
        topic:            @brief.topic,
        audience:         @brief.audience,
        duration_minutes: @brief.duration_minutes,
        desired_outcome:  @brief.desired_outcome,
        notes:            @brief.notes.present? ? "Additional Notes: #{@brief.notes}" : ""
      }
    )

    @agenda = @brief.build_workshop_agenda(
      user:       current_user,
      title:      @brief.topic,
      body:       result,
      gemini_raw: result
    )
    @agenda.save!
    redirect_to workshop_brief_agenda_path(@brief), notice: "Agenda generated."

  rescue GeminiService::BudgetExceededError
    @agenda_error = :budget_exceeded
    @agenda = nil
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::GatekeeperError
    @agenda_error = :gatekeeper_blocked
    @agenda = nil
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::TimeoutError
    @agenda_error = :timeout
    @agenda = nil
    render "workshop_briefs/show", status: :unprocessable_entity
  rescue GeminiService::GeminiError
    @agenda_error = :error
    @agenda = nil
    render "workshop_briefs/show", status: :unprocessable_entity
  end

  def show
    @agenda = current_user.workshop_agendas.find_by!(workshop_brief_id: @brief.id)
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  def destroy
    @brief.workshop_agenda&.destroy
    redirect_to @brief, notice: "Agenda deleted."
  end

  def export
    @agenda = current_user.workshop_agendas.find_by!(workshop_brief_id: @brief.id)
    render "workshop_agendas/export", layout: false, content_type: "text/plain"
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  private

  def set_brief
    @brief = current_user.workshop_briefs.find(params[:workshop_brief_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end
end
