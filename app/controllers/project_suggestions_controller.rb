# frozen_string_literal: true

class ProjectSuggestionsController < ApplicationController
  before_action :ensure_logged_in
  before_action :find_project, only: %i[new create]

  def new
    @project_suggestions = @project.project_suggestions.build(user: current_user)
  end

  def create
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
    params.require(:project_suggestion).permit(:licenses, :repository_url, :status, :notes)
  end
end
