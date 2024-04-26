# frozen_string_literal: true

require_relative "input_tsv_file"

namespace :one_off do
  # this table is huge and requires a manual batch-deletion
  desc "clean out repository_dependencies table"
  task batch_delete_repository_dependencies: :environment do
    RepositoryDependency.in_batches.each_with_index do |b, idx|
      b.delete_all
      if idx % 1000 == 0
        print "."
        sleep 1
      end
    end
  end

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
end
