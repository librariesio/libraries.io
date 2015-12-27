namespace :github do
  task update_old_users: :environment do
    GithubUser.visible.order('updated_at ASC').limit(10000).pluck(:login).each {|l| GithubUpdateUserWorker.perform_async(l);}
  end

  task remove_uninteresting_forks: :environment do
    GithubRepository.where(id: GithubRepository.fork.not_deprecated.open_source.where('stargazers_count < 1').without_projects.without_subscriptons.limit(200000).pluck(:id)).find_each(&:destroy)
  end

  task update_trending: :environment do
    trending = GithubRepository.open_source.where.not(pushed_at: nil).not_deprecated.recently_created.hacker_news.limit(30)
    brand_new = GithubRepository.open_source.where.not(pushed_at: nil).not_deprecated.recently_created.order('created_at DESC').limit(60)
    (trending + brand_new).uniq.each{|g| GithubCreateWorker.perform_async(g.full_name) }
  end
end
