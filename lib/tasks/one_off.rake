# frozen_string_literal: true

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
      good_name = p.name.gsub(/:/, "/")
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
  task backfill_missing_nuget_packages_2023_03: :environment do
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

  desc "Backfill Pypi project dependencies kind with environment markers"
  task :backfill_pypi_dependencies_kind, %i[batch_size start] => :environment do |_t, args|
    # There's ~5 million Pypi versions
    # Based on a sampling of 50k Pypi versions, ~50 (1/1000) contain environment markers
    # So in total there is an estimated 5k affected versions

    pypi_versions = Version.where(
      project_id: Project.where(platform: "Pypi")
    )

    # this batch size seems to keep the query below within a reasonable time limit
    batch_size = (args[:batch_size] && args[:batch_size].to_i) || 3000

    num_batches = pypi_versions.count / batch_size

    environment_markers = (PackageManager::Pypi::PEP_508_ENVIRONMENT_MARKERS - ["extra"])
      .map { |em| "'%#{em}%'" }
      .join(", ")

    pypi_versions.in_batches(of: batch_size, start: args[:start].to_i).each_with_index do |batch_versions, batch_versions_index|
      affected_versions = batch_versions
        .joins(:dependencies)
        .joins(:project)
        .where("dependencies.requirements LIKE any (array[#{environment_markers}])")
        .distinct

      puts "queuing batch #{batch_versions_index} of #{num_batches}"
      puts "#{affected_versions.count} versions in this batch affected"

      affected_versions.in_batches(of: 2).each_with_index do |batch_affected_versions, batch_affected_versions_index|
        batch_affected_versions
          .select("versions.number as project_version, projects.name as project_name")
          .each do |affected_version|
          PackageManagerDownloadWorker.perform_in(
            batch_versions_index.minute + batch_affected_versions_index.second,
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
end
