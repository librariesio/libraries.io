namespace :one_off do
  task clean_npm_versions: :environment do
    Project.platform('npm').find_each do |project|
      redundant_versions = project.versions.select do |version|
        Repositories::NPM.version_invalid?(project.name, version.number)
      end

      redundant_versions.each {|version| version.destroy }

      project.set_latest_release_published_at
      project.set_latest_release_number
      project.save!
    end
  end
end
