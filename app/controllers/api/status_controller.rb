class Api::StatusController < Api::BulkProjectController
  before_action :require_api_key

  def check
    render(
      json: projects,
      each_serializer: ProjectStatusSerializer,
      show_score: params[:score],
      show_stats: internal_api_key?,
      show_updated_at: internal_api_key?,
      project_names: project_names
    )
  end
end
