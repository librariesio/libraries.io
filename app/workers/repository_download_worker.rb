class RepositoryDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(class_name, name)
    klass = "Repositories::#{class_name}".constantize
    klass.update(name)
  end
end
