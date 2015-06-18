namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'update python repos'
  task update_python_repos: :environment do
    GithubRepository.where(language: 'Python').find_each(&:update_all_info_async)
  end
end
