# frozen_string_literal: true

class Api::StatusController < Api::BulkProjectController
  before_action :require_api_key

  def check
    serializer = OptimizedProjectSerializer.new(projects, project_names, internal_key: internal_api_key?)
    serialized = serializer.serialize
    dumped = Datadog::Tracing.trace("status_check_oj_dump", tags: { "project_ids" => projects.map(&:id) }) do |_span, _trace|
      Oj.dump(serialized, mode: :rails)
    end
    Datadog::Tracing.trace("status_check_render_dumped", tags: { "project_ids": projects.map(&:id) }) do |_span, _trace|
      render json: dumped
    end
  end
end
