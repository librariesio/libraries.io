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

  desc "Backfill Version#dependencies_count"
  task backfill_version_dependencies_count: :environment do
    versions = Version.where(dependencies_count: nil).where.associated(:dependencies).group("versions.id")

    puts "Updating #{versions.count.size} versions..."

    versions.in_batches(of: 1000).each_with_index do |batch, idx|
      batch.update_all("dependencies_count = (SELECT count(*) FROM dependencies WHERE dependencies.version_id = versions.id)")
      if idx % 100 == 0
        puts "#{versions.count.size} versions remaining...."
      end
    end
    puts "Finished updating versions"
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
  task :delete_ignored_maven_versions_and_resync_packages, %i[offset limit commit] => :environment do |_t, args|
    offset = args.offset&.to_i
    limit = args.limit&.to_i
    commit = args[:commit] == "yes"

    puts "DRY RUN" unless commit

    # Retrieve the projects where at least one version's repository_sources is not solely ["Maven"] or ["Google"]
    affected_projects = Project
      .joins(:versions)
      .where(platform: "Maven")
      .where(%((versions.repository_sources != '["Maven"]' AND versions.repository_sources != '["Google"]') OR repository_sources IS NULL))
      .distinct
    affected_projects = affected_projects.offset(offset) if offset.present?
    affected_projects = affected_projects.limit(limit) if limit.present?

    puts "Count of projects with versions to re-process: #{affected_projects.count}"

    batch_size = 50
    processed_count = 0

    puts "Processing...."
    affected_projects.find_each(batch_size: batch_size) do |project|
      no_source_versions = project.versions.where("repository_sources IS NULL")
      ignored_source_versions = project.versions.where(%((repository_sources != '["Maven"]' AND repository_sources != '["Google"]')))

      puts "Updating/Deleting #{no_source_versions.count + ignored_source_versions.count} versions for #{project.platform}/#{project.name}."

      if commit
        # If no repository_sources, then destroy it
        if no_source_versions.present?
          StructuredLog.capture(
            "DELETE_IGNORED_MAVEN_VERSIONS",
            {
              project_id: project.id,
              versions: no_source_versions.map(&:number).sort.join(", "),
              total_versions_count: no_source_versions.count,
              project_name: project.name,
              action: "remove_empty_source_versions",
            }
          )

          no_source_versions.destroy_all
        end

        # If there are repository_sources,
        # - if any are Maven or Google, remove repository_sources that aren't Maven or Google
        # - if none are Maven or Google, destroy version
        ignored_source_versions.in_batches do |versions_batch|
          versions_batch.each do |version|
            if version.repository_sources.include?("Maven") || version.repository_sources.include?("Google")
              StructuredLog.capture(
                "DELETE_IGNORED_MAVEN_VERSIONS",
                {
                  project_id: project.id,
                  project_name: project.name,
                  version: version.number,
                  action: "remove_invalid_sources",
                  original_sources: version.repository_sources,
                }
              )

              version.update(repository_sources: version.repository_sources.select { |source| %w[Maven Google].include?(source) })
            else
              StructuredLog.capture(
                "DELETE_IGNORED_MAVEN_VERSIONS",
                {
                  project_id: project.id,
                  project_name: project.name,
                  version: version.number,
                  action: "destroy_version",
                }
              )

              version.destroy
            end
          end
        end

        puts "Trying manual sync for #{project.platform}/#{project.name}."
        project.try(:manual_sync)
      end

      processed_count += 1
    end

    puts "Processed #{processed_count} projects."
  end

  # This should be run after the manual_syncs in delete_ignored_maven_versions_and_resync_packages are done
  desc "Delete Maven packages without versions"
  task :delete_maven_packages_without_versions, %i[commit] => :environment do |_t, args|
    commit = args.commit.present? && args.commit == "yes"

    puts "DRY RUN" unless commit

    batch_size = 10000
    processed_count = 0

    affected_projects = Project.where(platform: "Maven").without_versions
    affected_projects_count = affected_projects.count
    puts "Count of projects without versions to destroy: #{affected_projects_count}"
    puts "Processing...."
    affected_projects.in_batches(of: batch_size).each do |batch|
      processed_count += batch.size
      if commit
        batch.destroy_all
      else
        puts batch
      end
      puts "Destroyed #{processed_count} of #{affected_projects_count} projects."
    end
  end

  desc "Set maintenance_stats_refreshed_at on Repositories"
  task :set_maintenance_stats_refreshed_at_date, %i[commit] => :environment do |_t, args|
    puts "Preparing to set maintenance stats refresh date on GitHub repositories"
    batch_size = args.batch_size || 1000

    query = Repository.where.associated(:repository_maintenance_stats).where(host_type: "GitHub", maintenance_stats_refreshed_at: nil).select(:id).distinct
    total_left = query.count
    total_pages = (total_left / batch_size.to_f).ceil
    puts "#{total_left} repositories left to update"

    query.in_batches(of: batch_size).each_with_index do |batch, index|
      puts "Query batch #{index + 1} of #{total_pages}"

      repo_id_to_date = RepositoryMaintenanceStat
        .where(repository_id: batch.ids)
        .group("repository_id")
        .pluck("repository_id, max(updated_at)")
        .to_h

      puts "Finished gathering dates for batch #{index + 1}"

      upsert_hashes = batch.map do |repository|
        {
          id: repository.id,
          maintenance_stats_refreshed_at: repo_id_to_date.fetch(repository.id),
        }
      end

      Repository.upsert_all(
        upsert_hashes
      )

      puts "Updated all records in batch #{index + 1}"
    end

    puts "fin."
  end
end
