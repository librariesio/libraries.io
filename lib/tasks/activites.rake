namespace :activities do
  desc 'Download some dependency activity data for local development'
  task seed: :environment do
    project_name = 'csjs'
    p = PackageManager::NPM.update(project_name)
    p.update_repository
    p.repository.update_all_info
    p.repository.mine_dependencies
    repos = PackageManager::Base.get("https://libraries.io/api/npm/#{project_name}/dependent_repositories?per_page=50")
    repos.map!{|repo| CreateRepositoryWorker.new.perform(repo['host_type'], repo['full_name']) }
    repos.each do |repo|
      next if repo.nil?
      repo.update_all_info
      repo.mine_dependencies
    end
  end
end
