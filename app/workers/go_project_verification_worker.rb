# frozen_string_literal: true

class GoProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  def perform(name)
    project = Project.find_by(platform: "Go", name: name)

    # checks if the project name returns version results from Go Proxy
    # if the result comes back with a "gone" HTTP status, then remove the project from Libraries
    if PackageManager::Go.valid_project?(project.name)
      # valid project page
      unless PackageManager::Go.module?(project.name)
        # not a module
        # figure out what the correct module name is and if it exists already than this one can go
        # if it doesn't exist then call update for it to get it added
        module_name = PackageManager::Go.canonical_module_name(project.name)
        PackageManager::Go.update(module_name) unless Project.where(platform: "Go", name: module_name).exists?
        project.destroy
      end
    else
      project.destroy
    end
  end
end
