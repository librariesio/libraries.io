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

    puts '====='
    puts "Github Repos: #{GithubRepository.count}"
    puts "Remaining: #{Project.undownloaded_repos}"
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
    projects = Project.platform(platform).undownloaded_repos.where('repository_url ILIKE ?', '%github.com%').order('updated_at DESC')
    download_repos(projects)
  end

  def self.new_github_repos
    projects = Project.undownloaded_repos.where('repository_url ILIKE ?', '%github.com%').order('updated_at DESC')
    download_repos(projects)
  end

  def self.update_repos(platform)
    projects = Project.platform(platform).with_repository_url.order('updated_at DESC')
    download_repos(projects)
  end

  def self.download_repos(projects)
    projects.find_each(&:update_github_repo)
  end

  def self.download_contributors
    GithubRepository.each(&:download_github_contributions)
  end
end
