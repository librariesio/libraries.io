namespace :github do
  task update_old_users: :environment do
    GithubUser.visible.order('updated_at ASC').limit(10000).pluck(:login).each {|l| GithubUpdateUserWorker.perform_async(l);}
  end

  task sync_users: :environment do
    ids = GithubUser.visible.where(last_synced_at: nil).order('updated_at DESC').limit(50_000).pluck(:id)
    GithubUser.where(id: ids).find_each(&:async_sync)
  end

  task update_trending: :environment do
    trending = GithubRepository.open_source.where.not(pushed_at: nil).maintained.recently_created.hacker_news.limit(30).select('id')
    brand_new = GithubRepository.open_source.where.not(pushed_at: nil).maintained.recently_created.order('created_at DESC').limit(60).select('id')
    (trending + brand_new).uniq.each{|g| GithubDownloadWorker.perform_async(g.id) }
  end
end
