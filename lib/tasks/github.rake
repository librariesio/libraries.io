namespace :github do
  task sync_users: :environment do
    ids = GithubUser.visible.where(last_synced_at: nil).order('github_users.updated_at DESC').limit(50_000).pluck(:id)
    GithubUser.where(id: ids).find_each(&:async_sync)
  end

  task sync_project_repos: :environment do
    ids = GithubRepository.with_projects.where(last_synced_at: nil).order('github_repositories.updated_at DESC').limit(50_000).pluck(:id)
    GithubRepository.where(id: ids).find_each(&:update_all_info_async)
  end

  task update_trending: :environment do
    trending = GithubRepository.open_source.where.not(pushed_at: nil).maintained.recently_created.hacker_news.limit(30).select('id')
    brand_new = GithubRepository.open_source.where.not(pushed_at: nil).maintained.recently_created.order('created_at DESC').limit(60).select('id')
    (trending + brand_new).uniq.each{|g| GithubDownloadWorker.perform_async(g.id) }
  end
end
