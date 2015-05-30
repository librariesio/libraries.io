namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  task download_org_repos: :environment do
    GithubOrganisation.all.find_each(&:download_repos)
  end
end
