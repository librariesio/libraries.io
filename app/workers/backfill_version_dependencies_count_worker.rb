# frozen_string_literal: true

class BackfillVersionDependenciesCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, lock: :until_executed

  def perform
    versions = Version.where(dependencies_count: nil).where.associated(:dependencies)

    # 1 batch / 1000 records ~= 100ms, so 1 job run of 100 batches (100_000 records) ~= 10sec
    versions.group("versions.id").in_batches(of: 1000).take(100).each_with_index do |batch, _idx|
      batch.update_all("dependencies_count = (SELECT count(*) FROM dependencies WHERE dependencies.version_id = versions.id)")
    end

    if versions.exists?
      Rails.logger.info "BackfillVersionDependenciesCountWorker respawn."
      BackfillVersionDependenciesCountWorker.perform_async
    else
      Rails.logger.info "BackfillVersionDependenciesCountWorker finished."
    end
  end
end
