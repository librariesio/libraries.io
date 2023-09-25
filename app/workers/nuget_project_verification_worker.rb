# frozen_string_literal: true

# This worker is meant to verify if this package name is correct and is and we
# keep one canonically named record for each project.
class NugetProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  def perform(id)
    project = Project
      .platform("NuGet")
      .visible # Skip projects that are already out of circulation
      .find_by(id: id)

    return if project.nil?

    canonical_name = PackageManager::NuGet.fetch_canonical_nuget_name(project.name)
    return unless canonical_name

    if project.name != canonical_name
      # Soft-delete erroneous projects until we're sure it's safe to remove them
      project.update!(status: "Hidden")

      StructuredLog.capture(
        "PROJECT_MARKED_NONCANONICAL",
        {
          platform: project.platform,
          name: project.name,
          project_id: project.id,
          canonical_name: canonical_name,
        }
      )
    end
  end
end
