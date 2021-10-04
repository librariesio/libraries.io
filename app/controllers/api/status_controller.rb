# frozen_string_literal: true

class Api::StatusController < Api::BulkProjectController
  before_action :require_api_key

  def check
    serializer = OptimizedProjectSerializer.new(projects, project_names, internal_api_key?)
    render json: Oj.dump(serializer.serialize, :use_as_json => true, :mode => :rails)
  end
end
