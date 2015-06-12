namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'prepopulate dependents_count on projects'
  task prepopulate_dependents_count: :environment do
    Project.all.find_each(&:set_dependents_count)
  end
end
