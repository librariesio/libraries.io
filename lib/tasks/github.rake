namespace :github do
  task :update_users => :environment do
    GithubUser.visible.find_each(&:dowload_from_github)
  end
end
