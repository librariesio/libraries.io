namespace :github do
  task :update_users do
    GithubUser.find_each(&:dowload_from_github)
  end
end
