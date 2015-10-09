namespace :github do
  task update_old_users: :environment do
    GithubUser.visible.order('updated_at ASC').limit(10000).pluck(:login).each {|l| GithubUpdateUserWorker.perform_async(l);}
  end

  task remove_uninteresting_forks: :environment do
    GithubRepository.where(id: GithubRepository.fork.open_source.where('stargazers_count < 1').without_projects.without_subscriptons.without_manifests.limit(200000).pluck(:id)).find_each(&:destroy)    
  end
end
