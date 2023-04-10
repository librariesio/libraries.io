# frozen_string_literal: true
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
    ['npm', 'rubygems', 'packagist', 'nuget', 'cpan', 'clojars', 'cocoapods',
    'hackage', 'cran', 'atom', 'sublime', 'pub', 'elm', 'dub'].each do |platform|
      Project.platform(platform).not_removed.where('projects.updated_at < ?', 1.week.ago).select('id').find_each do |project|
        CheckStatusWorker.perform_async(project.id)
      end
    end
  end

  desc 'Update project repositories'
  task update_repos: :environment do
    exit if ENV['READ_ONLY'].present?
    projects = Project.maintained.where('projects.updated_at < ?', 1.week.ago).with_repo
    repos = projects.map(&:repository)
    repos.each do |repo|
      CreateRepositoryWorker.perform_async(repo.host_type, repo.full_name)
    end
  end

  desc 'Check project repositories statuses'
  task chech_repo_status: :environment do
    exit if ENV['READ_ONLY'].present?
    ['bower', 'go', 'elm', 'alcatraz', 'julia', 'nimble'].each do |platform|
      projects = Project.platform(platform).maintained.where('projects.updated_at < ?', 1.week.ago).order('projects.updated_at ASC').with_repo.limit(500)
      repos = projects.map(&:repository)
      repos.each do |repo|
        CheckRepoStatusWorker.perform_async(repo.host_type, repo.full_name)
      end
    end
  end

  desc 'Check to see if projects are still removed/deprecated'
  task check_removed_status: :environment do
    exit if ENV['READ_ONLY'].present?
    # Check if removed/deprecated projects are still deprecated/removed
    ['pypi', 'npm', 'rubygems', 'packagist', 'cpan', 'clojars', 'cocoapods',
    'hackage', 'cran', 'atom', 'sublime', 'pub', 'elm', 'dub'].each do |platform|
      Project.platform(platform).removed_or_deprecated.select('id').find_each do |project|
        CheckStatusWorker.perform_async(project.id, true)
      end
    end

    ['bower', 'go', 'elm', 'alcatraz', 'julia', 'nimble'].each do |platform|
      projects = Project.platform(platform).removed_or_deprecated.with_repo.limit(500)
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
    ['Alcatraz', 'Bower', 'Cargo', 'Clojars', 'CocoaPods', 'CRAN',
      'Dub', 'Elm', 'Hackage', 'Haxelib', 'Hex', 'Homebrew', 'Inqlude',
      'Julia', 'NPM', 'Packagist', 'Pypi', 'Rubygems'].each do |platform|
      "PackageManager::#{platform}".constantize.import_new_async rescue nil
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
        PackageManagerDownloadWorker.perform_async("PackageManager::#{platform}", name, nil, "potentially_outdated")
      end
    end
  end

  desc 'Refresh project_dependent_repos view'
  task refresh_project_dependent_repos_view: :environment do
    exit if ENV['READ_ONLY'].present?
    ProjectDependentRepository.refresh
  end

  supported_platforms = ['Maven', 'npm', 'Bower', 'PyPI', 'Rubygems', 'Packagist']

  desc 'Create maintenance stats for projects'
  task :create_maintenance_stats, [:number_to_sync] => :environment do |_task, args|
    exit if ENV['READ_ONLY'].present?
    number_to_sync = args.number_to_sync || 2000
    Project.no_existing_stats.where(platform: supported_platforms).limit(number_to_sync).each(&:update_maintenance_stats_async)
  end

  desc 'Update maintenance stats for projects'
  task :update_maintenance_stats, [:number_to_sync] => :environment do |_task, args|
    exit if ENV['READ_ONLY'].present?
    number_to_sync = args.number_to_sync || 2000
    Project.least_recently_updated_stats.where(platform: supported_platforms).limit(number_to_sync).each{|project| project.update_maintenance_stats_async(priority: :low)}
  end

  desc 'Set license_normalized flag'
  task set_license_normalized: :environment do
    supported_platforms = ["Maven", "NPM", "Pypi", "Rubygems", "NuGet", "Packagist"]
    Project.where(platform: supported_platforms, license_normalized: false).find_in_batches do |group|
      group.each do |project|
        project.normalize_licenses
        # check if we set a new value
        if project.license_normalized_changed?
          # update directly to skip any callbacks
          project.update_column(:license_normalized, project.license_normalized)
        end
      end
    end
  end

  desc 'Backfill old version licenses'
  task :backfill_old_version_licenses, [:name, :platform] => :environment do |_task, args|
    exit if ENV['READ_ONLY'].present?
    LicenseBackfillWorker.perform_async(args.platform, args.name)
  end

  desc 'Batch backfill old licenses'
  task :batch_backfill_old_version_licenses, [:platform] => :environment do |_task, args|
    projects = Project.where(platform: args.platform).joins(:versions).where("versions.original_license IS NULL").limit(15000).uniq
    projects.each do |project|
      LicenseBackfillWorker.perform_async(project.platform, project.name)
    end
  end

  desc 'Batch backfill conda'
  task backfill_conda: :environment do
    projects = PackageManager::Conda.all_projects
    projects.keys.each do |project_name|
      project = Project.find_by(platform: "Conda", name: project_name)
      if project.nil?
        PackageManager::Conda.update(project_name)
      elsif project.versions.count != projects[project_name]["versions"].count
        PackageManager::Conda.update(project_name)
        LicenseBackfillWorker.perform_async("Conda", project_name)
      else
        LicenseBackfillWorker.perform_async("Conda", project_name)
      end
    end
  end

  desc 'Update Go Base Modules'
  task :update_go_base_modules, [:version] => :environment do |_task, args|
    # go through versioned module names and rerun update on them to get their versions
    # added to the base module Project
    Project.where(platform: "Go").where("name like ?", "%/v#{args[:version]}").find_in_batches do |projects|
      projects.each do |project|
        matches = PackageManager::Go::VERSION_MODULE_REGEX.match(project.name)
        Project.find_or_create_by(platform: "Go", name: matches[1])
        PackageManagerDownloadWorker.perform_async("PackageManager::Go", project.name, nil, "update_go_base_modules")
        puts "Queued #{project.name} for update"
      end
    end
  end

  desc 'Verify Go Projects'
  task :verify_go_projects, [:count] => :environment do |_task, args|
    args.with_defaults(count: 1000)

    start_id = REDIS.get("go:update:latest_updated_id").presence || 0
    puts "Start id: #{start_id}, limit: #{args[:count]}."
    projects = Project
      .where(platform: "Go", repository_url: nil) # no repository_url is a common sign the package does not exist on pkg.go.dev
      .where("id > ?", start_id)
      .order(:id)
      .limit(args[:count])

    if projects.count.zero?
      puts "Done!"
      exit
    else
      projects
        .each { |p| GoProjectVerificationWorker.perform_async(p.name) }
      REDIS.set("go:update:latest_updated_id", projects.last.id)
    end
  end

  desc "Verify Pypi Projects"
  task :verify_pypi_projects, [:count] => :environment do |_task, args|
    args.with_defaults(count: 50)

    replace_cmd = "replace(lower(name), '-', '_')"
    puts "Querying for names with limit: #{args[:count]}"
    project_ids_and_names = Project
      .where(platform: "Pypi")
      .group(replace_cmd) # condense names down to all lower case and replace all hyphens with underscores since those are equal in pypi
      .having("count(name) > 1")
      .order("min(id)")# order this query so we can run through chunks of the results if needed
      .limit(args[:count])
      .pluck("min(id)", replace_cmd)

    puts "Found #{project_ids_and_names.count} names to verify"
    # project_ids_and_names is an array of arrays
    # [ [project_id, lowercased_name], [123, "name_with_underscores"] ]

    if project_ids_and_names.count.zero?
      puts "Done!"
      exit
    else
      project_ids_and_names
        .flat_map { |(_id, name)| Project.where(platform: "Pypi").where("#{replace_cmd} = ?", name) }
        .each do |project|
          puts "Queueing worker for #{project.name}"
          PypiProjectVerificationWorker.perform_async(project.name)
        end
    end
  end

  desc "Manual sync projects from list"
  task :sync_from_list, %i[input_file commit] => :environment do |_t, args|
    commit = args.commit.present? && args.commit == "yes"

    separator = "\t"
    batch_size = 50
    batch_wait = 5

    input_data = CSV.read(args.input_file, col_sep: separator, headers: false, skip_blanks: true)
    skipped_not_found_count = 0
    result_ids = []

    input_data.in_groups_of(batch_size, false).each do |platforms_and_names|
      projects = []
      platforms_and_names.each do |platform, name|
        project = Project.where("platform ILIKE ?", platform).find_by(name: name)

        if project
          projects << project
        else
          skipped_not_found_count += 1
          Rails.logger.warn("Project not found: #{platform}/#{name}")
        end
      end

      if commit
        projects.each(&:manual_sync)
        sleep batch_wait
      end

      result_ids.concat(projects.pluck(:id))
    end

    stats = <<~STATS
      Totals:
      Input:     #{input_data.count}
      Not found: #{skipped_not_found_count}
      Processed: #{result_ids.count}
    STATS

    Rails.logger.info(stats)
    Rails.logger.info("Project IDs: #{result_ids.join(", ")}")
    Rails.logger.info("\nThese changes have not been committed. Re-run this task with [,yes] to proceed.") unless commit
  end
end
