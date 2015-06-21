namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'cache languages'
  task cache_languages: :environment do
    Project.with_repo.includes(:github_repository).find_each do |project|
      project.update_columns(language: project.github_repository.try(:language))
    end
  end
end
