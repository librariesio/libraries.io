class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(project_id)
    project = Project.find_by_id project_id
    return unless project
    if project.platform.downcase == 'npm'
      response = Typhoeus.get("https://www.npmjs.com/package/#{project.name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    elsif project.platform.downcase == 'rubygems'
      response = Typhoeus.get("https://rubygems.org/gems/#{project.name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    end
  end
end
