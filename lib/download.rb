class Download
  def self.platforms
    Repositories.descendants
      .reject { |platform| platform == Repositories::Base }
      .sort_by(&:name)
  end

  def self.new_github_repos
    Project.undownloaded_repos.order('created_at DESC').find_each(&:update_github_repo_async)
  end

  def self.update_github_repos
    GithubRepository.order('updated_at ASC').find_each(&:update_all_info_async)
  end
end
