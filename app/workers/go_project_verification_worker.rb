# frozen_string_literal: true

class GoProjectVerificationWorker
  include Sidekiq::Worker

  def perform(name)
    project = Project.find_by(platform: "Go", name: name)

    # checks if the project name returns version results from Go Proxy
    # if the result comes back with a "gone" HTTP status, then remove the project from Libraries
    project.destroy unless PackageManager::Go.valid_project?(project.name)
  end
end
