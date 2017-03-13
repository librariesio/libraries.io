namespace :projects do
  desc 'Sync projects'
  task sync: :environment do
    ids = Project.where(last_synced_at: nil).order('projects.updated_at DESC').limit(100_000).pluck(:id)
    Project.where(id: ids).find_each(&:async_sync)
  end

  desc 'Update sourcerank of projects'
  task update_source_ranks: :environment do
    Project.where('projects.updated_at < ?', 1.week.ago).order('projects.updated_at ASC').limit(1000).each(&:update_source_rank_async)
  end

  desc 'Link dependencies to projects'
  task link_dependencies: :environment do
    Dependency.where('created_at > ?', 1.day.ago).without_project_id.with_project_name.find_each(&:update_project_id)
    RepositoryDependency.where('created_at > ?', 1.day.ago).without_project_id.with_project_name.find_each(&:update_project_id)
  end

  desc 'Check status of projects'
  task check_status: :environment do
    ['npm', 'rubygems', 'packagist', 'nuget', 'wordpress', 'cpan', 'clojars', 'cocoapods',
    'hackage', 'cran', 'atom', 'sublime', 'pub', 'elm', 'dub'].each do |platform|
      Project.platform(platform).not_removed.where('projects.updated_at < ?', 1.week.ago).select('id').find_each do |project|
        CheckStatusWorker.perform_async(project.id)
      end
    end
  end

  desc 'Update project repositoires'
  task update_repos: :environment do
    projects = Project.maintained.where('projects.updated_at < ?', 1.week.ago).with_repo
    repos = projects.map(&:repository)
    repos.each do |repo|
      CreateRepositoryWorker.perform_async(repo.host_type, repo.full_name)
    end
  end

  desc 'Check project repositoires statuses'
  task chech_repo_status: :environment do
    ['bower', 'go', 'elm', 'alcatraz', 'julia', 'nimble'].each do |platform|
      projects = Project.platform(platform).maintained.where('projects.updated_at < ?', 1.week.ago).with_repo
      repos = projects.map(&:repository)
      repos.each do |repo|
        CheckRepoStatusWorker.perform_async(repo.host_type, repo.full_name)
      end
    end
  end

  desc 'Check to see if projects have been removed'
  task check_removed_status: :environment do
    ['npm', 'rubygems', 'packagist', 'wordpress', 'cpan', 'clojars', 'cocoapods',
    'hackage', 'cran', 'atom', 'sublime', 'pub', 'elm', 'dub'].each do |platform|
      Project.platform(platform).removed.select('id').find_each do |project|
        CheckStatusWorker.perform_async(project.id, true)
      end
    end

    ['bower', 'go', 'elm', 'alcatraz', 'julia', 'nimble'].each do |platform|
      projects = Project.platform(platform).removed.with_repo
      repos = projects.map(&:repository)
      repos.each do |repo|
        CheckRepoStatusWorker.perform_async(repo.host_type, repo.full_name)
      end
    end
  end

  desc 'Check to see if nuget projects have been removed'
  task check_nuget_yanks: :environment do
    if Date.today.wday.zero?
      Project.platform('nuget').not_removed.includes(:versions).find_each do |project|
        if project.versions.all? { |version| version.published_at < 100.years.ago  }
          project.update_attribute(:status, 'Removed')
        end
      end
    end
  end

  desc 'Download missing packages'
  task download_missing: :environment do
    ['Atom', 'Cargo', 'CocoaPods', 'NPM', 'CPAN', 'CRAN', 'Elm', 'Hackage', 'Haxelib',
      'Hex', 'Packagist', 'Rubygems'].each do |platform|
      "PackageManager::#{platform}".constantize.import_new_async
    end
  end

  desc 'Slowly sync all pypi dependencies'
  task sync_pypi_deps: :environment do
    Project.maintained.platform('pypi').where('last_synced_at < ?', '2016-11-29 15:30:45').order(:last_synced_at).limit(10).each(&:async_sync)
  end
end
