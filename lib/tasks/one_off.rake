namespace :one_off do
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

  desc 'fill in host_type on existing repositories'
  task set_host_type: :environment do
    Repository.select(:id).find_in_batches do |repos|
      Repository.where(id: repos.map(&:id)).update_all host_type: 'GitHub'
    end
  end
end
