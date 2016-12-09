class TreeResolverWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform(version_id, kind, date = nil)
    version = Version.find(version_id)
    TreeResolver.new(version, kind, date).load_dependencies_tree if version
  end
end
