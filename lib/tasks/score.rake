# frozen_string_literal: true
namespace :scores do
  task seed: :environment do
    Rails.logger.level = Logger::DEBUG
    # start with projects that have zero runtime dependencies

    platform = 'Cargo'

    project_ids = Project.platform(platform).where(runtime_dependencies_count: 0).pluck(:id)

    while project_ids.any?
      batch = ProjectScoreCalculationBatch.new(platform, project_ids)
      project_ids = batch.process
    end
  end

  desc 'calculate scores for enqueued project ids'
  task calculate: :environment do
    ProjectScoreCalculationBatch.run_all_async
  end

  desc 'enqueue outdated project scores'
  task update: :environment do
    Project.where('score > 0').order('score_last_calculated ASC').limit(2000).each do |project|
      ProjectScoreCalculationBatch.enqueue(project.platform, [project.id])
    end
  end
end
