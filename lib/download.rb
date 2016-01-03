class Download
  def self.platforms
    @platforms ||= Repositories.constants
      .reject { |platform| platform == :Base }
      .map{|sym| "Repositories::#{sym}".constantize }
      .sort_by(&:name)
  end

  def self.format_name(platform)
    return nil if platform.nil?
    platforms.find{|p| p.to_s.demodulize.downcase == platform.downcase }.to_s.demodulize
  end

  def self.new_github_repos
    Project.undownloaded_repos.order('created_at DESC').find_each(&:update_github_repo_async)
  end

  def self.update_github_repos
    GithubRepository.order('updated_at ASC').find_each(&:update_all_info_async)
  end
end
