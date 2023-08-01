# frozen_string_literal: true

require_relative "./input_tsv_file"

namespace :projects do
  desc "Sync projects"
  task sync: :environment do
    exit if ENV["READ_ONLY"].present?
    Project.not_removed.order("last_synced_at ASC").where.not(last_synced_at: nil).limit(500).each(&:async_sync)
    Project.not_removed.where(last_synced_at: nil).order("updated_at ASC").limit(500).each(&:async_sync)
  end

  desc "Update lifting statuses of projects"
  task update_lifting_statuses: :environment do
    exit if ENV["READ_ONLY"].present?

    lifted_project_ids = FetchLiftedProjects.new.run.map(&:id)

    newly_unlifted_projects = Project.where(lifted: true).where.not(id: lifted_project_ids)
    newly_lifted_projects = Project.where(lifted: false).where(id: lifted_project_ids)

    newly_unlifted_projects.each do |p|
      puts "[UNLIFTED] platform=#{p.platform} name=#{p.name}"
    end

    newly_lifted_projects.each do |p|
      puts "[LIFTED] platform=#{p.platform} name=#{p.name}"
    end

    newly_unlifted_projects.update_all(lifted: false)
    newly_lifted_projects.update_all(lifted: true)
  end

  desc "Update sourcerank of projects"
  task update_source_ranks: :environment do
    exit if ENV["READ_ONLY"].present?
    Project.where("projects.updated_at < ?", 1.week.ago).order("projects.updated_at ASC").limit(500).each(&:update_source_rank_async)
  end

  desc "Link dependencies to projects"
  task link_dependencies: :environment do
    exit if ENV["READ_ONLY"].present?
    ids = Dependency.where("created_at::date >= date(?)", 1.day.ago).without_project_id.pluck(:id)
    Rails.logger.info("Found #{ids.count} Dependency IDs")

    total_slices = (ids.count / 1000.to_f).ceil
    ids.each_slice(1000).with_index do |group, index|
      Rails.logger.info("Updating slice #{index + 1} of #{total_slices}")
      Dependency.where(id: group).each(&:update_project_id)
    end

    ids = RepositoryDependency.where("created_at::date >= date(?)", 1.day.ago).without_project_id.pluck(:id)
    Rails.logger.info("Found #{ids.count} RepositoryDependency IDs")

    total_slices = (ids.count / 1000.to_f).ceil
    ids.each_slice(1000).with_index do |group, index|
      Rails.logger.info("Updating slice #{index + 1} of #{total_slices}")
      RepositoryDependency.where(id: group).each(&:update_project_id)
    end
  end

  # rake projects:check_status[100,5]
  desc "Check status of projects"
  task :check_status, %i[max_num_of_projects_to_check batch_size] => :environment do |_task, args|
    exit if ENV["READ_ONLY"].present?

    platforms_for_status_checks = %w[cargo cocoapods conda go maven npm nuget packagist pypi rubygems].freeze

    max_num_of_projects_to_check = args.max_num_of_projects_to_check.nil? ? 150_000 : args.max_num_of_projects_to_check.to_i
    batch_size = args.batch_size.nil? ? 10000 : args.batch_size.to_i

    project_ids_to_check = Project
      .platform(platforms_for_status_checks)
      .where("status_checked_at IS NULL OR status_checked_at < ?", 1.week.ago)
      .order("status_checked_at ASC NULLS FIRST")
      .limit(max_num_of_projects_to_check)
      .select("id")

    enqueued_projects_sum = 0
    project_ids_to_check.in_batches(of: batch_size) do |project_ids_batch|
      enqueued_projects_sum += project_ids_batch.count

      project_ids_batch.pluck(:id).each_with_index do |project_id, i|
        CheckStatusWorker.perform_in(i, project_id)
      end

      log_string = "#{enqueued_projects_sum} of up to #{max_num_of_projects_to_check} jobs were enqueued"

      Rails.logger.info("logger: #{log_string}")
      puts("puts: #{log_string}")
    end
  end

  desc "Update project repositories"
  task update_repos: :environment do
    exit if ENV["READ_ONLY"].present?
    projects = Project.maintained.where("projects.updated_at < ?", 1.week.ago).with_repo
    repos = projects.map(&:repository)
    repos.each do |repo|
      CreateRepositoryWorker.perform_async(repo.host_type, repo.full_name)
    end
  end

  desc "Check project repositories statuses"
  task chech_repo_status: :environment do
    exit if ENV["READ_ONLY"].present?
    %w[bower go elm alcatraz julia nimble].each do |platform|
      projects = Project.platform(platform).maintained.where("projects.updated_at < ?", 1.week.ago).order("projects.updated_at ASC").with_repo.limit(500)
      repos = projects.map(&:repository)
      repos.each do |repo|
        CheckRepoStatusWorker.perform_async(repo.host_type, repo.full_name)
      end
    end
  end

  desc "Check to see if nuget projects have been removed"
  task check_nuget_yanks: :environment do
    exit if ENV["READ_ONLY"].present?
    Project.platform("nuget").not_removed.includes(:versions).find_each do |project|
      project.update_attribute(:status, "Removed") if project.versions.all? { |version| version.published_at < 100.years.ago }
    end
  end

  desc "Download missing packages"
  task download_missing: :environment do
    exit if ENV["READ_ONLY"].present?
    %w[Alcatraz Bower Cargo Clojars CocoaPods CRAN
       Dub Elm Hackage Haxelib Hex Homebrew Inqlude
       Julia NPM Packagist Pypi Rubygems].each do |platform|
         "PackageManager::#{platform}".constantize.import_new_async
    rescue StandardError
      nil
       end
  end

  desc "Slowly sync all pypi dependencies"
  task sync_pypi_deps: :environment do
    exit if ENV["READ_ONLY"].present?
    Project.maintained.platform("pypi").where("last_synced_at < ?", "2016-11-29 15:30:45").order(:last_synced_at).limit(10).each(&:async_sync)
  end

  desc "Sync potentially outdated projects"
  task potentially_outdated: :environment do
    exit if ENV["READ_ONLY"].present?
    rd_names = RepositoryDependency.where("created_at > ?", 1.hour.ago).select("project_name,platform").distinct.pluck(:platform, :project_name).map { |r| [PackageManager::Base.format_name(r[0]), r[1]] }
    d_names = Dependency.where("created_at > ?", 1.hour.ago).select("project_name,platform").distinct.pluck(:platform, :project_name).map { |r| [PackageManager::Base.format_name(r[0]), r[1]] }
    all_names = (d_names + rd_names).uniq

    all_names.each do |platform, name|
      project = Project.platform(platform).find_by_name(name)
      if project
        begin
          project.async_sync if project.potentially_outdated?
        rescue StandardError
          nil
        end
      else
        PackageManagerDownloadWorker.perform_async("PackageManager::#{platform}", name, nil, "potentially_outdated")
      end
    end
  end

  desc "Refresh project_dependent_repos view"
  task refresh_project_dependent_repos_view: :environment do
    exit if ENV["READ_ONLY"].present?
    ProjectDependentRepository.refresh
  end

  supported_platforms = %w[Maven npm Bower PyPI Rubygems Packagist]

  desc "Create maintenance stats for projects"
  task :create_maintenance_stats, [:number_to_sync] => :environment do |_task, args|
    exit if ENV["READ_ONLY"].present?
    number_to_sync = args.number_to_sync || 2000
    Project.no_existing_stats.platform(supported_platforms).limit(number_to_sync).each(&:update_maintenance_stats_async)
  end

  desc "Update maintenance stats for projects"
  task :update_maintenance_stats, [:number_to_sync] => :environment do |_task, args|
    exit if ENV["READ_ONLY"].present?
    number_to_sync = args.number_to_sync || 2000
    Project.least_recently_updated_stats.platform(supported_platforms).limit(number_to_sync).each { |project| project.update_maintenance_stats_async(priority: :low) }
  end

  desc "Set license_normalized flag"
  task set_license_normalized: :environment do
    supported_platforms = %w[Maven NPM Pypi Rubygems NuGet Packagist]
    Project.platform(supported_platforms).where(license_normalized: false).find_in_batches do |group|
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

  desc "Backfill old version licenses"
  task :backfill_old_version_licenses, %i[name platform] => :environment do |_task, args|
    exit if ENV["READ_ONLY"].present?
    LicenseBackfillWorker.perform_async(args.platform, args.name)
  end

  desc "Batch backfill old licenses"
  task :batch_backfill_old_version_licenses, [:platform] => :environment do |_task, args|
    platform = args.platform
    projects = Project.platform(platform).joins(:versions).where("versions.original_license IS NULL").limit(15000).distinct
    projects.each do |project|
      LicenseBackfillWorker.perform_async(project.platform, project.name)
    end
  end

  desc "Batch backfill conda"
  task backfill_conda: :environment do
    projects = PackageManager::Conda.all_projects
    projects.each_key do |project_name|
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

  desc "Update Go Base Modules"
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

  desc "Verify Go Projects"
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
      .order("min(id)") # order this query so we can run through chunks of the results if needed
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

    skipped_not_found_count = 0
    result_ids = []

    input_tsv_file = InputTsvFile.new(args.input_file)

    input_tsv_file.in_batches do |platforms_and_names|
      projects = []
      platforms_and_names.each do |platform, name|
        project = Project.platform(platform).find_by(name: name)

        if project
          projects << project
        else
          matching_project = Project.platform(platform).where("name ILIKE ?", name).first

          message = ["Project not found: #{platform}/#{name}"]

          message << "Potential matching project found #{matching_project.platform}/#{matching_project.name}" if matching_project

          skipped_not_found_count += 1
          Rails.logger.warn(message.join(", "))
        end
      end

      projects.each(&:manual_sync) if commit

      result_ids.concat(projects.pluck(:id))
    end

    stats = <<~STATS
      Totals:
      Input:     #{input_tsv_file.count}
      Not found: #{skipped_not_found_count}
      Processed: #{result_ids.count}
    STATS

    Rails.logger.info(stats)
    Rails.logger.info("Project IDs: #{result_ids.join(', ')}")
    Rails.logger.info("\nThese changes have not been committed. Re-run this task with [,yes] to proceed.") unless commit
  end
end
