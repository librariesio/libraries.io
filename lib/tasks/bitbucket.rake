namespace :bitbucket do
  task find_new_repos: :environment do
    latest_bb_repo = Repository.host('BitBucket').order('created_at DESC').first
    if latest_bb_repo
      after = (latest_bb_repo.created_at + 1.second).to_s(:iso8601)
    else
      after = nil
    end
    Repository.recursive_bitbucket_repos("https://api.bitbucket.org/2.0/repositories?pagelen=100&after=#{after}")
  end

  task find_existing_repos: :environment do
    Project.with_bitbucket_url.find_each(&:update_repository_async)
  end
end
