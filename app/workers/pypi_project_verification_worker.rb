# frozen_string_literal: true

# This worker is meant to verify if this package name is correct and found on the resources used as the
# Pypi platform's source of truth. If a project name is not found, then go ahead and delete the Project from libraries.
class PypiProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  def perform(name)
    project = Project.find_by(platform: "Pypi", name: name)

    return unless project.present?

    # check to see if the module is found on pkg.go.dev and if it isn't then go ahead and delete this name
    return project.destroy unless PackageManager::Pypi.valid_project?(project.name)
  end
end
