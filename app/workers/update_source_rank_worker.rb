class UpdateSourceRankWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :low, unique: true

  def perform(project_id)
    project = Project.find(project_id)
    project.update_source_rank
  end
end
