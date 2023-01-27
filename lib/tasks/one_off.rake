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
    Project.
      where(platform: "Clojars").
      where("name LIKE '%:%'").
      find_each do |p|
        good_name, bad_name = p.name.gsub(/:/, '/'), p.name
        puts "Updating #{good_name}, deleting #{bad_name}"
        PackageManager::Clojars.update(good_name)
        p.destroy!
    end
  end

  desc "delete all hidden maven projects missing a group id"
  task delete_groupless_maven_projects: :environment do
    Project.
      where(platform: "Maven").
      where(status: "Hidden").
      where("name NOT LIKE '%:%'").
      find_each do |p|
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
  task :backfill_pypi_version_dependencies, [:limit] => :environment do |_t, args|
    Version
      .joins(:project)
      .where(projects: {
        platform: "Pypi"
      })
      .where("versions.created_at > ?", Date.new(2022, 7, 6))
      .where(versions: {
        runtime_dependencies_count: [0, nil]
      })
      .select('versions.number, projects.name')
      .limit(args[:limit])
      .each do |v|
        PackageManager::Pypi.save_dependencies(
          {
            name: v.name
          },
          sync_version: v.number
        )
      end
  end
end
