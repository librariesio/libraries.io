namespace :bitbucket do
  task find_new_repos: :environment do
    after = REDIS.get('bitbucket-after')
    after_param = after ? "&after=#{after}" : nil
    Repository.recursive_bitbucket_repos("https://api.bitbucket.org/2.0/repositories?pagelen=100#{after_param}")
  end

  task find_existing_repos: :environment do
    Project.with_bitbucket_url.without_repo.find_each(&:update_repository_async)
  end
end
