class DashboardController < ApplicationController
  def show
    redirect_to workshop_briefs_path
  end
end
