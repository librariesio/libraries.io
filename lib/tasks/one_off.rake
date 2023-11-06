# frozen_string_literal: true

require_relative "input_tsv_file"

namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc "set stable flag on all versions"
  task set_stable_versions: :environment do
    Version.find_in_batches do |versions|
      ActiveRecord::Base.transaction do
        versions.each do |v|
          v.update_column(:stable, v.stable_release?)
        end
      end
    end
  end

  desc "set stable flag on all tags"
  task set_stable_tags: :environment do
    Tag.find_in_batches do |tags|
      ActiveRecord::Base.transaction do
        tags.each do |t|
          t.update_column(:stable, t.stable_release?)
        end
      end
    end
  end

  desc "backfill missing clojars packages with a slash, and remove packages with a dot"
  task cleanup_clojar_projects: :environment do
    Project
      .where(platform: "Clojars")
      .where("name LIKE '%:%'")
      .find_each do |p|
        good_name = p.name.gsub(":", "/")
        bad_name = p.name
        puts "Updating #{good_name}, deleting #{bad_name}"
        PackageManager::Clojars.update(good_name)
        p.destroy!
      end
  end

  desc "delete all hidden maven projects missing a group id"
  task delete_groupless_maven_projects: :environment do
    Project
      .where(platform: "Maven")
      .where(status: "Hidden")
      .where("name NOT LIKE '%:%'")
      .find_each do |p|
        puts "Deleting Maven project #{p.name} (#{p.id})"
        p.destroy!
      end
  end

  desc "remove all duplicate repository_maintenance_stats, preferring the one most recently updated."
  task dedupe_repository_maintenance_stats: :environment do
    sql = Arel.sql(
      <<-SQL
        DELETE FROM repository_maintenance_stats
        WHERE id IN
        (
            SELECT id
            FROM(
                SELECT *, row_number() OVER (PARTITION BY repository_id, category ORDER BY updated_at DESC)
                FROM repository_maintenance_stats
            ) as s
            WHERE row_number > 1
        )
      SQL
    )

    ActiveRecord::Base.connection.execute(sql)
  end

  desc "backfill missing pypi version dependencies"
  task backfill_pypi_version_dependencies: :environment do
    Project
      .joins(:versions)
      .where("versions.created_at > ? AND last_synced_at < ?", Date.new(2022, 7, 6), Date.new(2023, 2, 1))
      .where(platform: "Pypi")
      .distinct
      .select("name")
      .in_batches(of: 120).each_with_index do |batch, batch_index|
        batch.in_groups_of(2).each_with_index do |project_group, project_group_index|
          project_group.each do |project|
            PackageManagerDownloadWorker.perform_in((batch_index - 1).minute + project_group_index.second, "pypi", project.name, nil, "backfill")
          end
        end
      end
  end

  # this can be run repeatedly until each package has been checked
  desc "Backfill NuGet packages that might have been missed while using a deprecated API"
  task backfill_missing_nuget_packages_2023_03: :environment do # rubocop: disable Naming/VariableNumber
    packages = File.readlines("lib/tasks/input/2023-03-nuget_packages_to_check.txt").map(&:strip)

    processed = 0

    packages.each do |package_name|
      puts "Checking #{package_name}..."
      next if Project.where(platform: "NuGet").find_by("name ilike '#{package_name}'")

      puts "#{package_name} not found, updating..."
      Project.transaction do
        PackageManager::NuGet.update(package_name)
      end
      processed += 1
      puts "Done, #{processed} total updated"
      sleep 0.5
    end

    print "Total examined: #{packages.count}, Total created: #{processed}"
  end

  desc "Backfill Project.status_checked_at with Project.updated_at value"
  task backfill_project_status_checked_at: :environment do
    projects = Project
      .where(status_checked_at: nil)

    puts "Updating #{projects.count} projects..."

    projects.in_batches(of: 10000).each do |batch|
      batch.update_all("status_checked_at = updated_at")
    end

    print "Finished updating projects"
  end

  desc "Correct Pypi dependency names with extras and kind"
  task :correct_pypi_dependencies_name_and_kind, %i[batch_size start] => :environment do |_t, args|
    pypi_versions = Version.where(project_id: Project.where(platform: "Pypi"))

    batch_size = (args[:batch_size]&.to_i) || 10000

    num_batches = pypi_versions.count / batch_size

    pypi_versions.in_batches(of: batch_size, start: args[:start].to_i).each_with_index do |batch_versions, batch_versions_index|
      affected_versions = batch_versions
        .joins(:dependencies)
        .distinct
        .where("dependencies.requirements LIKE '[%' OR dependencies.optional IS TRUE")

      puts "queuing batch #{batch_versions_index} of #{num_batches}"
      puts "#{affected_versions.count} versions in this batch affected"

      affected_versions.in_batches(of: 4).each_with_index do |batch_affected_versions, batch_affected_versions_index|
        batch_affected_versions
          .joins(:project)
          .select("versions.number as project_version, projects.name as project_name")
          .each do |affected_version|
            PackageManagerDownloadWorker.perform_in(
              batch_versions_index.minute + batch_affected_versions_index.seconds,
              "pypi",
              affected_version.project_name,
              affected_version.project_version,
              "pypi-kind-backfill",
              0,
              true
            )
          end
      end
    end
  end

  # Maven dependencies were being incorrectly added using the internal name of
  # the repository source from which we found the dependency.
  desc "Correct Maven dependencies platforms"
  task :correct_maven_dependencies_platforms, %i[batch_size start] => :environment do |_t, args|
    maven_versions = Version.where(project_id: Project.where(platform: "Maven"))

    batch_size = (args[:batch_size]&.to_i) || 10000

    num_batches = maven_versions.count / batch_size

    maven_versions.in_batches(of: batch_size, start: args[:start].to_i).each_with_index do |batch_versions, batch_versions_index|
      affected_versions = batch_versions
        .joins(:dependencies)
        .distinct
        .where.not(dependencies: { platform: "Maven" })

      puts "queuing batch #{batch_versions_index} of #{num_batches}"
      puts "#{affected_versions.count} versions in this batch affected"

      affected_versions.in_batches(of: 4).each_with_index do |batch_affected_versions, _batch_affected_versions_index|
        Dependency.where(version: batch_affected_versions).update(platform: "Maven")
      end
    end
  end

  # This find and fixes PyPI packages provided in the CSV file which have
  # incorrect published_at dates due to the main project API missing version
  # details.
  desc "Correct PyPI versions for packages in CSV file"
  task :correct_pypi_versions_for_packages_in_csv_file, %i[input_file commit] => :environment do |_t, args|
    commit = args.commit.present? && args.commit == "yes"
    input_tsv_file = InputTsvFile.new(args.input_file)

    corrected_count = 0

    input_tsv_file.in_batches do |platforms_and_names|
      platforms_and_names.each do |_platform, name|
        db_project = Project.platform("Pypi").find_by(name: name)

        unless db_project
          puts "Can't find db project #{name}"
          next
        end

        puts "Checking #{name}..."
        json_api_project = PackageManager::Pypi::JsonApiProject.request(project_name: name)

        unless json_api_project.present?
          puts "PyPI returned a nil API response: #{name}"
          next
        end

        releases = json_api_project.releases

        unless releases.all_releases_have_published_at?
          puts "Project #{name} is missing published_at details"
          rss_api_project = PackageManager::Pypi::RssApiReleases.request(project_name: name)
          rss_api_releases = rss_api_project.releases

          matching_rss_releases = releases.reject(&:published_at?).map do |release|
            rss_api_releases.find { |rss_release| rss_release.version_number == release.version_number }
          end.compact

          matching_rss_releases.each do |rss_release|
            db_version = db_project.versions.find_by(number: rss_release.version_number)

            next unless db_version

            if db_version.published_at && ((db_version.published_at - rss_release.published_at).abs < 10)
              # if the times are within 10 seconds of each other, don't update the record
              next
            end

            corrected_count += 1

            if commit
              db_version.update(published_at: rss_release.published_at)
              puts "Updated #{name} version #{rss_release.version_number} published_at to #{rss_release.published_at}"
            else
              puts "Would update published_at on this version to #{rss_release.published_at}"
              pp db_version
            end
          end
        end

        sleep 0.25
      end

      sleep 1
    end

    puts "Results:"
    puts "Total packages checked: #{input_tsv_file.count}"
    puts "Versions corrected: #{corrected_count}"
  end

  desc "Delete ignored Maven versions and resync packages"
  task :delete_ignored_maven_versions_and_resync_packages, %i[commit] => :environment do |_t, args|
    commit = args.commit.present? && args.commit == "yes"

    puts "DRY RUN" unless commit

    # Retrieve the projects where at least one version's repository_sources is not solely ["Maven"] or ["Google"]
    affected_projects = Project
      .joins(:versions)
      .where(platform: "Maven")
      .where(%(versions.repository_sources != '["Maven"]' AND versions.repository_sources != '["Google"]' OR repository_sources IS NULL))
      .distinct

    puts "Count of projects with versions to re-process: #{affected_projects.count}"

    batch_size = 50
    processed_count = 0

    puts "Processing...."
    affected_projects.in_batches(of: batch_size).each do |batch|
      batch.each do |project|
        affected_versions = project.versions.where(%(repository_sources != '["Maven"]' AND repository_sources != '["Google"]' OR repository_sources IS NULL))

        puts "Destroying #{affected_versions.count} versions for #{project.platform}/#{project.name}."
        affected_versions.destroy_all if commit

        # Use versions count manually because it might be unsafe to trust
        # cached project.versions_count value immediately after doing deletions
        if project.versions.count > 0
          puts "Versions remaining for #{project.platform}/#{project.name}: Trying manual sync."
          project.try(:manual_sync) if commit
        else
          puts "No versions remaining for #{project.platform}/#{project.name}: Destroying project."
          project.destroy! if commit
        end
      end

      processed_count += [batch_size, batch.size].min
      puts "Processed #{processed_count} projects"
    end
  end
end
