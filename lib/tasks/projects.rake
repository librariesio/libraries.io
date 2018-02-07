namespace :projects do
  desc 'Sync projects'
  task sync: :environment do
    exit if ENV['READ_ONLY'].present?
    Project.not_removed.order('last_synced_at ASC').where.not(last_synced_at: nil).limit(500).each(&:async_sync)
    Project.not_removed.where(last_synced_at: nil).order('updated_at ASC').limit(500).each(&:async_sync)
  end

  desc 'Update sourcerank of projects'
  task update_source_ranks: :environment do
    exit if ENV['READ_ONLY'].present?
    Project.where('projects.updated_at < ?', 1.week.ago).order('projects.updated_at ASC').limit(500).each(&:update_source_rank_async)
  end

  desc 'Link dependencies to projects'
  task link_dependencies: :environment do
    exit if ENV['READ_ONLY'].present?
    Dependency.where('created_at > ?', 1.day.ago).without_project_id.with_project_name.find_each(&:update_project_id)
    RepositoryDependency.where('created_at > ?', 1.day.ago).without_project_id.with_project_name.find_each(&:update_project_id)
  end

  desc 'Check status of projects'
  task check_status: :environment do
    exit if ENV['READ_ONLY'].present?
    ['npm', 'rubygems', 'packagist', 'nuget', 'wordpress', 'cpan', 'clojars', 'cocoapods',
    'hackage', 'cran', 'atom', 'sublime', 'pub', 'elm', 'dub'].each do |platform|
      Project.platform(platform).not_removed.where('projects.updated_at < ?', 1.week.ago).select('id').find_each do |project|
        CheckStatusWorker.perform_async(project.id)
      end
    end
  end

  desc 'Update project repositoires'
  task update_repos: :environment do
    exit if ENV['READ_ONLY'].present?
    projects = Project.maintained.where('projects.updated_at < ?', 1.week.ago).with_repo
    repos = projects.map(&:repository)
    repos.each do |repo|
      CreateRepositoryWorker.perform_async(repo.host_type, repo.full_name)
    end
  end

  desc 'Check project repositoires statuses'
  task chech_repo_status: :environment do
    exit if ENV['READ_ONLY'].present?
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
    exit if ENV['READ_ONLY'].present?
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
    exit if ENV['READ_ONLY'].present?
    Project.platform('nuget').not_removed.includes(:versions).find_each do |project|
      if project.versions.all? { |version| version.published_at < 100.years.ago  }
        project.update_attribute(:status, 'Removed')
      end
    end
  end

  desc 'Download missing packages'
  task download_missing: :environment do
    exit if ENV['READ_ONLY'].present?
    ['Alcatraz', 'Atom', 'Bower', 'Cargo', 'Clojars', 'CocoaPods', 'CRAN',
      'Dub', 'Elm', 'Emacs', 'Hackage', 'Haxelib', 'Hex', 'Homebrew', 'Inqlude',
      'Julia', 'NPM', 'Packagist', 'Pypi', 'Rubygems'].each do |platform|
      "PackageManager::#{platform}".constantize.import_new_async
    end
  end

  desc 'Slowly sync all pypi dependencies'
  task sync_pypi_deps: :environment do
    exit if ENV['READ_ONLY'].present?
    Project.maintained.platform('pypi').where('last_synced_at < ?', '2016-11-29 15:30:45').order(:last_synced_at).limit(10).each(&:async_sync)
  end

  desc 'Sync potentially outdated projects'
  task potentially_outdated: :environment do
    exit if ENV['READ_ONLY'].present?
    rd_names = RepositoryDependency.where('created_at > ?', 1.hour.ago).select('project_name,platform').distinct.pluck(:platform, :project_name).map{|r| [PackageManager::Base.format_name(r[0]), r[1]]}
    d_names = Dependency.where('created_at > ?', 1.hour.ago).select('project_name,platform').distinct.pluck(:platform, :project_name).map{|r| [PackageManager::Base.format_name(r[0]), r[1]]}
    all_names = (d_names + rd_names).uniq

    all_names.each do |platform, name|
      project = Project.platform(platform).find_by_name(name)
      if project
        project.async_sync if project.potentially_outdated? rescue nil
      else
        PackageManagerDownloadWorker.perform_async(platform, name)
      end
    end
  end
end
