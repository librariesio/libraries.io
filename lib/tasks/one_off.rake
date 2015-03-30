namespace :one_off do
  task clean_packagist_versions: :environment do
    Project.platform('packagist').find_each do |project|
      redundant_versions = project.versions.where("number LIKE 'dev-%'")
      redundant_versions.destroy_all

      project.set_latest_release_published_at
      project.set_latest_release_number
      project.save!
    end
  end

  task clean_dub_versions: :environment do
    Project.platform('dub').find_each do |project|
      redundant_versions = project.versions.where("number LIKE '~%'")
      redundant_versions.destroy_all

      project.set_latest_release_published_at
      project.set_latest_release_number
      project.save!
    end
  end

  task clean_npm_versions: :environment do
    Project.platform('npm').find_each do |project|
      redundant_versions = project.versions.reject do |version|
        Repositories::NPM.version_valid?(project.name, version.number)
      end

      redundant_versions.each {|version| version.destroy }

      project.set_latest_release_published_at
      project.set_latest_release_number
      project.save!
    end
  end
end
