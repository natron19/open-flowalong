class WorkshopBriefsController < ApplicationController
  before_action :set_brief, only: [:show, :edit, :update, :destroy]

  def index
    @briefs = current_user.workshop_briefs.order(updated_at: :desc)
  end

  def new
    @brief = WorkshopBrief.new
  end

  def create
    @brief = current_user.workshop_briefs.build(brief_params)
    if @brief.save
      redirect_to @brief, notice: "Workshop brief created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @agenda = @brief.workshop_agenda
  end

  def edit; end

  def update
    if @brief.update(brief_params)
      redirect_to @brief, notice: "Brief updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @brief.destroy
    redirect_to workshop_briefs_path, notice: "Workshop deleted."
  end

  private

  def set_brief
    @brief = current_user.workshop_briefs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found
  end

  def brief_params
    params.require(:workshop_brief).permit(:topic, :audience, :duration_minutes, :desired_outcome, :notes)
  end
end
