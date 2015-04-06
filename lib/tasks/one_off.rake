namespace :one_off do
  task download_missing_users: :environment do
    GithubRepository.where('(select count(*) from github_users where github_id=github_repositories.owner_id) = 0').find_each do |repo|
      repo.download_github_contributions
    end
  end
end
