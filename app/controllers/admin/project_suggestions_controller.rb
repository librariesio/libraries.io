class Admin::ProjectSuggestionsController < Admin::ApplicationController
  def index
    @project_suggestions = ProjectSuggestion.all.paginate(page: params[:page])
  end
end
