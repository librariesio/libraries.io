class Download
  def self.platforms
    Repositories.descendants
      .reject { |platform| platform == Repositories::Base }
      .sort_by(&:name)
  end

  def self.new_github_repos
    Project.undownloaded_repos.order('created_at ASC').find_each(&:update_github_repo)
  end

  def self.download_contributors
    GithubRepository.order('created_at DESC').includes(:projects, :github_contributions).find_each do |repo|
      next if repo.projects.empty? || repo.github_contributions.any?
      repo.download_github_contributions
    end
  end

  def self.update_github_repos
    GithubRepository.order('updated_at ASC').find_each(&:update_from_github)
  end
end
