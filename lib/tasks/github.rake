namespace :github do
  task update_old_users: :environment do
    GithubUser.visible.order('updated_at ASC').limit(10000).pluck(:login).each {|l| GithubUpdateUserWorker.perform_async(l);}
  end

  task remove_uninteresting_forks: :environment do
    GithubRepository.where(id: GithubRepository.fork.open_source.where('stargazers_count < 1').without_projects.without_subscriptons.limit(200000).pluck(:id)).find_each(&:destroy)
  end

  task update_trending: :environment do
    GithubRepository.open_source.where.not(pushed_at: nil).recently_created.order('created_at DESC').limit(1000).each{|g| GithubCreateWorker.perform_async(g.full_name) }
    GithubRepository.open_source.where.not(pushed_at: nil).recently_created.hacker_news.limit(1000).each{|g| GithubCreateWorker.perform_async(g.full_name) }
  end
end
