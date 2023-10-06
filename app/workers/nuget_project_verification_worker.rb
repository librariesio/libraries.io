# frozen_string_literal: true

# This worker is meant to verify if this package name is correct and is and we
# keep one canonically named record for each project.
class NugetProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, retry: 3, unique: :until_executed

  def perform(id)
    project = Project
      .platform("NuGet")
      .visible # Skip projects that are already out of circulation
      .find_by(id: id)

    return if project.nil?

    canonical_name = PackageManager::NuGet.fetch_canonical_nuget_name(project.name)

    logging_info = {
      platform: project.platform.downcase,
      name: project.name,
      project_id: project.id,
      canonical_name: canonical_name,
    }

    if canonical_name.nil?
      # Retry if the fetch failed
      raise SidekiqQuietRetryError, "FETCH_CANONICAL_NAME_FAILED"
    elsif canonical_name == false
      if project.removed?
        StructuredLog.capture("CANONICAL_NAME_ELEMENT_MISSING_PROJECT_REMOVED", logging_info)
      else
        StructuredLog.capture("CANONICAL_NAME_ELEMENT_MISSING_PROJECT_NOT_REMOVED", logging_info)
        CheckStatusWorker.perform_async(project.id)
      end

      return false
    end

    if project.name != canonical_name
      # Soft-delete erroneous projects until we're sure it's safe to remove them
      project.update!(status: "Hidden")

      StructuredLog.capture("PROJECT_MARKED_NONCANONICAL", logging_info)
    end
  end
end
