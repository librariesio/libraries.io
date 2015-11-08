class ProjectSuggestionsController < ApplicationController
  before_action :ensure_logged_in

  def new
    find_project
    @project_suggestions = @project.project_suggestions.build(user: current_user)
  end

  def create
    find_project
    @project_suggestions = @project.project_suggestions.build(user: current_user)
    if @project_suggestions.update_attributes(project_suggestion_params)
      flash[:notice] = "Thanks for the suggestion, we'll update the project shortly"
      redirect_to project_path(@project.to_param)
    else
      render :new
    end
  end

  private

  def project_suggestion_params
    params.require(:project_suggestion).permit(:licenses, :repository_url, :notes)
  end
end
