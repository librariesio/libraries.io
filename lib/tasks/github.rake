namespace :github do
  task :update_users => :environment do
    GithubUser.visible.find_each(&:dowload_from_github)
  end

  task reparse_manifests: :environment do
    GithubRepository.with_manifests.find_each do |repo|
      repo.manifests.delete_all
      repo.update_all_info_async
    end
  end

  task parse_new_manifests: :environment do
    GithubRepository.includes(:projects, :manifests).where(projects: {github_repository_id: nil}, manifests: {github_repository_id: nil}).find_each do |repo|
      repo.update_all_info_async
    end
  end
end
