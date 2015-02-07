namespace :projects do
  task normalize_licenses: :environment do
    Project.where("licenses <> ''").where("normalized_licenses != '{}'").find_each do |project|
      project.normalize_licenses
      project.save
    end
  end
end
