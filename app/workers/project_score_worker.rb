# frozen_string_literal: true

class ProjectScoreWorker
  include Sidekiq::Worker
  sidekiq_options queue: :score, lock: :until_executed

  def perform(platform)
    ProjectScoreCalculationBatch.run(platform)
  end
end
