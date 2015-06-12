namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'prepopulate contributions_count on repos'
  task prepopulate_contributions_count: :environment do
    GithubContribution.counter_culture_fix_counts
  end
end
