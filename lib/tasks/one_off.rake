namespace :one_off do
  task clean_packagist_versions: :environment do
    Project.platform('packagist').find_each do |project|
      redundant_versions = project.versions.where("number LIKE 'dev-%' OR number LIKE '~%'")
      redundant_versions.destroy_all

      project.set_latest_release_published_at
      project.set_latest_release_number
      project.save!
    end
  end
end
