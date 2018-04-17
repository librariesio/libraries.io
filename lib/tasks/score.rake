namespace :scores do
  task seed: :environment do
    Rails.logger.level = Logger::DEBUG
    # start with projects that have zero runtime dependencies

    platform = 'Cargo'

    project_ids = Project.platform(platform).pluck(:id)

    while project_ids.any?
      p project_ids
      batch = ProjectScoreCalculationBatch.new(platform, project_ids)
      project_ids = batch.process
    end
  end
end
