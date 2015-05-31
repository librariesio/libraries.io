namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  task convert_keywords: :environment do
    Project.where("keywords <> ''").find_each do |project|
      project.update_attribute(:keywords_array, project.keywords.split(',').uniq.compact)
    end
  end
end
