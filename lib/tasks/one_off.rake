namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  task download_more_repos: :envirnoment do
    GithubUser.order('created_at ASC').limit(10_000).find_each(&:download_repos)
  end
end
