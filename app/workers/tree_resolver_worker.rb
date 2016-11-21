class TreeResolverWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform(version_id, kind)
    version = Version.find(version_id)
    TreeResolver.new(version, kind).load_dependencies_tree if version
  end
end
