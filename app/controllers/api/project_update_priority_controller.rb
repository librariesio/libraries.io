class Api::ProjectUpdatePriorityController < Api::ApplicationController
  before_action :require_internal_api_key, :find_project

  def update
    priority = ProjectUpdatePriority.find_or_create_by(project: @project)
    priority.priority = params[:priority]
    priority.save! if priority.changed?
    head :ok
  rescue ArgumentError
    render json: { error: "Error 400. Priority invalid" }, status: :bad_request
  end
end
