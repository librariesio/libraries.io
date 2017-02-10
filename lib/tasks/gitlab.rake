namespace :gitlab do
  task find_repos: :environment do
    page_number = REDIS.get('gitlab-page') || 1
    Repository.recursive_gitlab_repos(page_number)
  end
end
