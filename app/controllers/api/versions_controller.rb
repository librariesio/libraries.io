# frozen_string_literal: true

class Api::VersionsController < Api::BulkProjectController
  before_action :require_internal_api_key

  MAX_RESULTS = 500

  def index
    @max_results = [Integer(params[:max_results] || MAX_RESULTS), MAX_RESULTS].min

    @versions = Version
      .includes(:project)
      .where.not(projects: { id: nil })
      .where(
        "versions.updated_at > ?",
        Time.parse(params.require(:since))
      ).order(:updated_at)
  end
end
