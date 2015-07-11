namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'get popular repos'
  task update_popular_repos: :environment do
    Project.popular_languages(:facet_limit => 25).map(&:term).each do |language|
      AuthToken.client.search_repos("language:#{language} stars:<500", sort: 'stars').items.each do |repo|
        GithubRepository.create_from_hash repo.to_hash
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
end
