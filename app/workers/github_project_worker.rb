class GithubProjectWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(project_id)
    project = Project.find(project_id)
    project.update_github_repo
    project.update_source_rank_async
  end
end
