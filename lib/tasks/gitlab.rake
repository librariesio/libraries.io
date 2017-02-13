namespace :gitlab do
  task find_new_repos: :environment do
    page_number = REDIS.get('gitlab-page') || 1
    Repository.recursive_gitlab_repos(page_number)
  end

  task find_existing_repos: :environment do
    Project.with_gitlab_url.find_each(&:update_repository_async)
  end
end
