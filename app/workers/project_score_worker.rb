class ProjectScoreWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(platform)
    ProjectScoreCalculationBatch.run(platform)
  end
end
