namespace :projects do
  task recreate_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Project.__elasticsearch__.client.indices.delete index: 'projects' rescue nil
    Project.__elasticsearch__.create_index! force: true
  end

  task reindex: [:environment, :recreate_index] do
    Project.import query: -> { includes(:github_repository => :github_tags) }
  end

  task update_source_ranks: :environment do
    ids = Project.order('updated_at ASC').limit(10_000).pluck(:id).to_a
    Project.includes([{:github_repository => [:readme, :github_tags]}, :versions, :github_contributions]).where(id: ids).find_each(&:update_source_rank)
  end

  task link_dependencies: :environment do
    Dependency.without_project_id.find_each(&:update_project_id)
  end
end
