# frozen_string_literal: true

namespace :maintenance_stats do
  desc "Gather maintenance stats for a list of repositories"
  task :gather_maintenance_stats, %i[input_file commit] => :environment do |_t, args|
    commit = args.commit.present? && args.commit == "yes"
    data = CSV.read(args.input_file, headers: false)

    skipped_no_package_count = 0
    skipped_no_repository_count = 0
    data.each do |package_info|
      # libraries platform casing varies
      project = Project.find_by("platform ILIKE ? AND name LIKE ?", package_info[0], package_info[1])

      unless project
        Rails.logger.info("Did not find project: #{package_info[0]}/#{package_info[0]}")
        skipped_no_package_count += 1
        next
      end

      repository = project.repository
      unless repository
        Rails.logger.info("Did not find repository: #{package_info[1]}/#{package_info[1]}")
        skipped_no_repository_count += 1
        next
      end

      project.repository.gather_maintenance_stats if commit
    end
  end
end
