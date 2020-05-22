# frozen_string_literal: true

class LicenseBackfillWorker
  include Sidekiq::Worker

  def perform(platform, name)
    project = Project.find_by(platform: platform, name: name)

    pm = project.platform_class
    json_project = pm.project(project.name)
    versions = pm.versions(json_project, project.name)
    versions.each do |vers|
      version = project.versions.find_by(number: vers[:number])
      version.update(original_license: vers[:original_license]) if version&.original_license.nil?
    end
  end
end
