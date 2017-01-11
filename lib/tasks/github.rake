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
    GithubUser.visible.where(last_synced_at: nil).limit(100).each(&:async_sync)
    GithubUser.visible.order('last_synced_at ASC').limit(100).each(&:async_sync)
  end

  task sync_orgs: :environment do
    GithubOrganisation.visible.order('last_synced_at ASC').limit(200).each(&:async_sync)
  end

  task sync_repos: :environment do
    scope = GithubRepository.source.open_source
    scope.where(last_synced_at: nil).limit(100).each(&:update_all_info_async)
    scope.order('last_synced_at ASC').limit(100).each(&:update_all_info_async)
  end

  task sync_issues: :environment do
    scope = GithubIssue.includes(:github_repository)
    scope.help_wanted.indexable.order('last_synced_at ASC').limit(100).each(&:sync)
    scope.first_pull_request.indexable.order('last_synced_at ASC').limit(100).each(&:sync)
    scope.order('last_synced_at ASC').limit(100).each(&:sync)
  end

  task update_trending: :environment do
    trending = GithubRepository.open_source.pushed.maintained.recently_created.hacker_news.limit(30).select('id')
    brand_new = GithubRepository.open_source.pushed.maintained.recently_created.order('created_at DESC').limit(60).select('id')
    (trending + brand_new).uniq.each{|g| GithubDownloadWorker.perform_async(g.id) }
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
      puts "#{since} - #{'%.4f' % (since.to_f/250000)}%"
      puts '*'*20
      sleep 0.5
    end
  end
end
