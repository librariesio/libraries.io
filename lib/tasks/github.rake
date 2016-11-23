namespace :github do
  task recreate_repos_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    GithubRepository.__elasticsearch__.client.indices.delete index: 'github_repositories' rescue nil
    GithubRepository.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex the repo search'
  task reindex_repos: [:environment, :recreate_repos_index] do
    GithubRepository.indexable.import
  end

  task recreate_issues_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    GithubIssue.__elasticsearch__.client.indices.delete index: 'github_issues' rescue nil
    GithubIssue.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex the issues search'
  task reindex_issues: [:environment, :recreate_issues_index] do
    GithubIssue.indexable.import
  end

  task sync_users: :environment do
    ids = GithubUser.visible.where(last_synced_at: nil).order('github_users.updated_at DESC').limit(50_000).pluck(:id)
    GithubUser.where(id: ids).find_each(&:async_sync)
  end

  task sync_project_repos: :environment do
    ids = GithubRepository.with_projects.order('github_repositories.last_synced_at ASC').limit(50_000).pluck(:id)
    GithubRepository.where(id: ids).find_each(&:update_all_info_async)
  end

  task update_trending: :environment do
    trending = GithubRepository.open_source.pushed.maintained.recently_created.hacker_news.limit(30).select('id')
    brand_new = GithubRepository.open_source.pushed.maintained.recently_created.order('created_at DESC').limit(60).select('id')
    (trending + brand_new).uniq.each{|g| GithubDownloadWorker.perform_async(g.id) }
  end

  task update_issues: :environment do
    ids = GithubIssue.where('last_synced_at < ?', Date.parse('2016-05-02T15:37:07Z')).uniq.pluck(:github_repository_id)
    ids.each{|id| GithubDownloadWorker.perform_async(id) }
  end

  task update_repos: :environment do
    ids = GithubRepository.open_source.maintained.where('last_synced_at < ?', Date.parse('2016-05-01T15:37:07Z')).where(has_issues: true).source.pluck(:id)
    ids.each{|id| GithubDownloadWorker.perform_async(id) }
  end

  task download_all_users: :environment do
    since = REDIS.get('githubuserid').to_i

    while true
      users = AuthToken.client(auto_paginate: false).all_users(since: since)
      users.each do |o|
        begin
          if o.type == "Organization"
            GithubOrganisation.find_or_create_by(github_id: o.id) do |u|
              u.login = o.login
            end
          else
            GithubUser.create_from_github(o)
          end
        rescue
          nil
        end
      end
      since = users.last.id + 1
      REDIS.set('githubuserid', since)
      puts '*'*20
      puts "#{since} - #{'%.4f' % (since.to_f/226000)}%"
      puts '*'*20
    end
  end
end
