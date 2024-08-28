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

  # This task tracks down the original "published" dates for NuGet Versions that
  # are marked as "published_at=1900-01-01 00:00:00" in Libraries, and updates
  # them with the original "published" date, and marks them 'status: "Deprecated"'.
  #
  # It processes lists-of-lists from NuGet's API:
  #   * [CatalogRoot] Catalog API (https://learn.microsoft.com/en-us/nuget/api/catalog-resource)
  #     * .items => [CatalogPage]
  #       * .items => [PackageDetails] (each PackageDetails may contain the original "published")
  #
  # @param catalog_start_idx Integer the index of the catalog page to start with,
  #                          to skip already-processed pages (default: 0)
  # @param threads Integer the number of parallel threads to process version items (default: 8)
  desc "backfill unknown nuget published_at dates"
  task :backfill_nuget_published_at, %i[catalog_start_idx threads] => :environment do |_t, args|
    require "parallel"

    catalog_start_idx = args.catalog_start_idx.to_i
    threads = args.threads || 8

    print "Loading 'unlisted' NuGet Version records... "
    unlisted_name_versions = Version
      .joins(:project)
      .where(projects: { platform: "NuGet" })
      .where("published_at < ?", DateTime.new(1901, 1, 1))
      .pluck("projects.name, versions.number")
      .index_by(&:itself)
    puts "found #{unlisted_name_versions.size} records."

    print "Loading NuGet's catalog listing of events pages... "
    catalog = PackageManager::ApiService.request_json_with_headers("https://api.nuget.org/v3/catalog0/index.json")
    catalog_size = catalog["items"].size
    puts "found #{catalog_size} pages."

    catalog["items"]
      .sort_by { |catalog_item| catalog_item["@id"].split("/").last.gsub(/page/, "").gsub(/\.json/, "").to_i }
      .each.with_index do |catalog_item, idx|
        next if idx < catalog_start_idx

        page_filename = catalog_item["@id"].split("/").last

        puts "Processing NuGet catalog page #{page_filename} (idx #{idx}), out of #{catalog_size} pages..."
        page = PackageManager::ApiService.request_json_with_headers(catalog_item["@id"])

        Parallel.each(page["items"], in_threads: threads.to_i, progress: "Page #{idx} out of #{catalog_size}, with #{page['items'].size} items") do |item|
          retries = 0
          page_item = nil
          while page_item.nil? && retries < 3
            sleep 0.5 if retries > 0 # Give NuGet server a short break and retry
            page_item = PackageManager::ApiService.request_json_with_headers(item["@id"])
            retries += 1
          end
          if page_item.nil?
            puts "\n !!!!!!!!!!!!!!!!!!!!!!!! Found a page without @id: #{item} !!!!!!!!!!!!!!!!!!!!!!!!!!!!! \n"
            next
          end
          name = page_item["id"]
          version = page_item["version"]
          published = page_item["published"]

          if published.nil?
            raise "'published' field not found on page #{catalog_item['@id']} in #{item['@id']}."
          elsif unlisted_name_versions.key?([name, version]) && published !~ /1900-/
            p = Project.find_by(platform: "NuGet", name: name)
            v = p.versions.find_by(number: version)
            if v.published_at.year == 1900
              published_at = Time.parse(published)
              v.update_columns(published_at: published, status: "Deprecated")
              unlisted_name_versions.delete([name, version])
              puts "Updating #{p.name}@#{v.number} to #{published_at}."
            else
              puts "Skipping #{p.name}@#{v.number}. Version is already #{v.published_at}."
            end
          end
        end
      end
    puts "Catalog page idx #{idx} (#{(idx / catalog_size.to_f) * 100}% complete)"
  end

  # @param start_id String The id of the Project to resume from,
  #                         to skip already-processed projects (default: nil)
  # @param commit String Must equal 'yes' to perform changes
  desc "Backfill maven dependencies after bugfixes"
  task :backfill_maven_dependencies, %i[start_id commit] => :environment do |_t, args|
    start = args.start_id
    commit = args.commit == "yes"

    bugfix_timestamp = Date.new(2024, 8, 28).beginning_of_day

    projects = Project.platform("Maven")
      .not_removed
      .joins(:repository_maintenance_stats)
      .where("last_synced_at < ?", bugfix_timestamp)
      .distinct

    projects.find_in_batches(start: start, batch_size: 1000).with_index do |project_batch, batch_number|
      puts "!! Updating batch ##{batch_number + 1} of Maven project dependencies (#{project_batch.first.id} - #{project_batch.last.id})"

      project_batch.each do |project|
        project.async_sync(force_sync_dependencies: true) if commit
      end

      sleep 600
    end
  end
end
