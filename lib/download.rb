class Download
  def self.platforms
    Repositories.descendants.reject{|platform| platform == Repositories::Base }
  end
  def self.total
    platforms.sum { |pm| pm.project_names.length }
  end

  def self.import
    platforms.each(&:import)
  end

  def self.keys
    platforms.flat_map(&:keys).map(&:to_s).sort.uniq
  end

  def self.github_repos
    Project.with_repository_url.limit(1000).offset(120)
      .select(&:github_url)
      .compact
      .reject(&:github_repository)
      .each(&:update_github_repo)
  end
end
