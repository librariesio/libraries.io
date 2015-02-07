class Download
  def self.platforms
    Repositories.descendants
      .reject { |platform| platform == Repositories::Base }
      .sort_by(&:name)
  end

  def self.new_github_repos
    projects = Project.undownloaded_repos.order('updated_at DESC')
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
    GithubRepository.order('updated_at ASC').find_each(&:download_github_contributions)
  end

  def self.update_github_repos
    GithubRepository.order('updated_at ASC').find_each(&:update_from_github)
  end

  def self.stats
    downloaded = 0
    total = 0
    counts = {}
    platforms.each do |platform|
      counts[platform] = {
        count: Project.platform(platform.name.to_s.demodulize).count,
        available: platform.project_names.length
      }
    end
    github_count = GithubRepository.count
    github_total = Project.undownloaded_repos

    counts.each do |platform, values|
      puts platform.name.to_s.demodulize
      puts "  Dowloaded: #{values[:count]}"
      puts "  Available: #{values:[available]}"
      puts "  Diff: #{values[:available] - values[:count]}"
      downloaded += values[:count]
      total += values[:available]
    end

    puts '====='
    puts "  Total Dowloaded: #{downloaded}"
    puts "  Total Available: #{total}"
    puts "  Total Diff: #{total - downloaded}"

    puts '====='
    puts "Github Repos: #{github_count}"
    puts "Remaining: #{github_total}"
  end
end
