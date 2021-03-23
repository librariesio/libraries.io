# frozen_string_literal: true

class Api::VersionsController < Api::BulkProjectController
  before_action :require_internal_api_key

  def index
    @versions = Version.includes(:project).where(
      "versions.updated_at > ?",
      Time.parse(params.require(:since))
    )
  end
end
