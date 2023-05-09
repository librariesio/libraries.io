# frozen_string_literal: true

class Admin::ProjectSuggestionsController < Admin::ApplicationController
  def index
    @project_suggestions = ProjectSuggestion.all.order("created_at DESC").joins(:project).paginate(page: params[:page], per_page: 100)
  end

  def destroy
    @project_suggestion = ProjectSuggestion.find(params[:id])
    @project_suggestion.destroy
    redirect_to admin_project_suggestions_path
  end
end
