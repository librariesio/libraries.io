# frozen_string_literal: true

# This worker is meant to verify if this package name is correct and found on the resources used as the
# Pypi platform's source of truth. If a project name is not found, then go ahead and delete the Project from libraries.
class PypiProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  def perform(name)
    project = Project.find_by(platform: "Pypi", name: name)

    return if project.nil? || project&.is_removed?

    # check to see if the module is found on pypi and it is a case sensitive match to the name data on pypi
    project.destroy! unless PackageManager::Pypi.has_canonical_pypi_name?(project.name)
  end
end
