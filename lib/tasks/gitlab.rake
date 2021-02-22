# frozen_string_literal: true
namespace :gitlab do
  task find_new_repos: :environment do
    exit if ENV['READ_ONLY'].present?
    page_number = REDIS.get('gitlab-page') || 1
    RepositoryHost::Gitlab.recursive_gitlab_repos(page_number)
  end

  task find_updated_repos: :environment do
    exit if ENV['READ_ONLY'].present?
    RepositoryHost::Gitlab.recursive_gitlab_repos(1, 10, 'last_activity_desc')
  end

  task find_existing_repos: :environment do
    exit if ENV['READ_ONLY'].present?
    Project.with_gitlab_url.without_repo.find_each(&:update_repository_async)
  end
end
