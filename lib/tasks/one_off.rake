namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'get popular repos'
  task update_popular_repos: :environment do
    Project.popular_languages(:facet_limit => 20).map(&:term).each do |language|
      AuthToken.client.search_repos("language:#{language} stars:<300", sort: 'stars').items.each do |repo|
        GithubRepository.create_from_hash repo.to_hash
      end
    end
  end

  desc 'get popular users'
  task update_popular_users: :environment do
    Project.popular_languages(:facet_limit => 100).map(&:term).each do |language|
      AuthToken.client.search_users("language:#{language}", sort: 'followers').items.each do |item|
        user = GithubUser.find_or_create_by(github_id: item.id) do |u|
          u.login = item.login
          u.user_type = item.type
          u.name = item.name
          u.company = item.company
          u.blog = item.blog
          u.location = item.location
        end
      end
    end
  end

  desc 'fix git urls'
  task fix_git_urls: :environment do
    Project.where('repository_url LIKE ?', 'https://github.com/git+%').find_each do |p|
      p.repository_url.gsub!('https://github.com/git+', 'https://github.com/')
      p.save
    end
  end

  desc 'delete duplicate repos'
  task delete_duplicate_repos: :environment do
    repo_ids = GithubRepository.select(:github_id).group(:github_id).having("count(*) > 1").pluck(:github_id)

    repo_ids.each do |repo_id|
      repos = GithubRepository.where(github_id: repo_id).includes(:projects, :repository_subscriptions)
      # keep one repo

      # remove if no projects or repository_subscriptions
      for_removal = repos.select do |repo|
        repo.projects.empty? && repo.repository_subscriptions.empty?
      end

      for_removal.each_with_index do |repo, index|
        next if index.zero?
        repo.destroy
      end
    end
  end
end
