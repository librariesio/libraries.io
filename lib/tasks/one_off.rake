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

  desc "backfill all latest_stable_release_numbers"
  task backfill_latest_stable_release_numbers: :environment do
    count = 0
    Project.
      where(latest_stable_release_number: nil).
      find_each do |p|
      p.set_latest_stable_release_info
      count += 0
    end
  ensure
    puts "Backfilled #{count} projects' latest_stable_release_number."
  end
end
