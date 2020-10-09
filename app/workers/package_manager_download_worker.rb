# frozen_string_literal: true

class PackageManagerDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical

  def perform(class_name, name)
    return unless class_name.present?

    # need to maintain compatibility with things that pass in the name of the class under PackageManager module
    logger.info("Beginning update for #{class_name}/#{name}")
    class_name.constantize.update(name)
  end
end
