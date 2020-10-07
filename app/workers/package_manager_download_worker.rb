# frozen_string_literal: true

class PackageManagerDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical

  def perform(clazz, name)
    return unless clazz.present?

    # need to maintain compatibility with things that pass in the name of the class under PackageManager module
    clazz = "PackageManager::#{clazz}".constantize if clazz.is_a? String
    logger.info("Beginning update for #{clazz.name}/#{name}")
    clazz.update(name)
  end
end
