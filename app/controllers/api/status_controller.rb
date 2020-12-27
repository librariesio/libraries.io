# frozen_string_literal: true

class Api::StatusController < Api::BulkProjectController
  before_action :require_api_key

  def check
    if params[:v2] == "true"
      check_new
    else
      check_legacy
    end
  end

  def check_legacy
    render(
      json: projects,
      each_serializer: ProjectStatusSerializer,
      show_score: params[:score],
      show_stats: internal_api_key?,
      show_updated_at: internal_api_key?,
      project_names: project_names
    )
  end

  def check_new
    # This forces serialization with Oj
    # TODO: Investigate calling Oj.mimic_JSON on initializationh to swap universally
    serializer = OptimizedProjectSerializer.new(projects, project_names, internal_api_key?)
    render json: Oj.dump(serializer.serialize)
  end
end
