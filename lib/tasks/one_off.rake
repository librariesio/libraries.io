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
    Project.popular_languages(:facet_limit => 20).map(&:term).each do |language|
      AuthToken.client.search_users("language:#{language} followers:<500", sort: 'followers').items.each do |item|
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

  desc 'download orgs'
  task download_orgs: :environment do
    GithubUser.find_each do |user|
      user.download_orgs
    end
  end

  desc 'update user repos'
  task update_user_repos: :environment do
    User.find_each do |user|
      user.update_repo_permissions
      user.adminable_github_repositories.each{|g| g.update_all_info_async user.token }
    end
  end

  desc 'mark users who need token upgrade'
  task token_upgrade: :environment do
    User.where.not(public_repo_token: nil).update_all(token_upgrade: true)
    User.where.not(private_repo_token: nil).update_all(token_upgrade: true)
  end
end
