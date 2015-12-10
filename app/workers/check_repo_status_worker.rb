class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(repo_full_name)
    response = Typhoeus.head("https://github.com/#{repo_full_name}")

    if response.response_code == 404
      repo = GithubRepository.includes(:projects).find_by_full_name(repo_full_name)
      if repo
        repo.projects.each do |project|
          project.update_attribute(:status, 'Removed')
        end
      end
    end
  end
end
