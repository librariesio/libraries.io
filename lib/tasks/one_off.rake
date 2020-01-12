namespace :one_off do
  desc 'backfill Dependency#version_project'
  task backfill_dependency_version_project: :environment do
    max_id = Dependency.maximum(:id)
    scope = Dependency.where(version_project_id: nil)
    puts "Before: #{scope.count}"
    scope.includes(:version).find_in_batches do |b|
      b.each do |dep|
        dep.set_version_project_id
        dep.save
        puts "#{((dep.id / max_id.to_f) * 100).round(3)}% done." if dep.id % 1_000_000 == 0
      end
    end
    puts "After: #{scope.count}"
  end

  # put your one off tasks here and delete them once they've been ran
  desc 'set stable flag on all versions'
  task set_stable_versions: :environment do
    Version.find_in_batches do |versions|
      ActiveRecord::Base.transaction do
        versions.each do |v|
          v.update_column(:stable, v.stable_release?)
        end
      end
    end
  end

  desc 'set stable flag on all tags'
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
