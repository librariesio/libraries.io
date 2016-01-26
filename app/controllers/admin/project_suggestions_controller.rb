class Admin::ProjectSuggestionsController < Admin::ApplicationController
  def index
    @project_suggestions = ProjectSuggestion.all.order('created_at DESC').paginate(page: params[:page])
  end
end
