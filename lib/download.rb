class Download
  def self.stats
    downloaded = 0
    total = 0
    platforms.each do |platform|
      count = Project.platform(platform.name.to_s.demodulize).count
      available = platform.project_names.length
      puts platform.name.to_s.demodulize
      puts "  Dowloaded: #{count}"
      puts "  Available: #{available}"
      puts "  Diff: #{available - count}"
      downloaded += count
      total += available
    end
    puts '====='
    puts "  Total Dowloaded: #{downloaded}"
    puts "  Total Available: #{total}"
    puts "  Total Diff: #{total - downloaded}"
  end

  def self.platforms
    Repositories.descendants
      .reject { |platform| platform == Repositories::Base }
      .sort_by(&:name)
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

  def self.github_repos(platform)
    projects = Project.platform(platform).with_repository_url
      .where('id NOT IN (SELECT DISTINCT(project_id) FROM github_repositories)')
      .select(&:github_url)
      .compact
    download_repos(projects)
  end

  def self.new_github_repos
    projects = Project.with_repository_url
    .where('id NOT IN (SELECT DISTINCT(project_id) FROM github_repositories)')
    .select(&:github_url)
    .compact
    download_repos(projects)
  end

  def self.update_repos(platform)
    projects = Project.platform(platform).with_repository_url.select(&:github_url).compact
    download_repos(projects)
  end

  def self.download_repos(projects)
    Parallel.each(projects, :in_threads => 5) do |project|
      ActiveRecord::Base.connection_pool.with_connection do
        project.update_github_repo
      end
    end
  end

  def self.download_contributors(platform)
    Project.platform(platform).map(&:github_repository)
      .compact.each(&:download_github_contributions)
  end
end
