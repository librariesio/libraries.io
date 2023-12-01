# frozen_string_literal: true

class UpdateSourceRankWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sourcerank, lock: :until_executed

  def perform(project_id)
    Project.find_by_id(project_id).try(:update_source_rank)
  end
end
