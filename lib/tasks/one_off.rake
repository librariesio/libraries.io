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
end
