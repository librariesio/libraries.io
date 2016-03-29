class GithubProjectWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(project_id)
    project = Project.find_by_id(project_id)
    if project
      project.update_github_repo
      project.update_source_rank_async
    end
  end
end
