namespace :search do
  desc 'Recreate repo search index'
  task recreate_repos_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Repository.__elasticsearch__.client.indices.delete index: "repositories-#{Rails.env}" rescue nil
    Repository.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex the repo search'
  task reindex_repos: [:environment, :recreate_repos_index] do
    Repository.indexable.import
  end

  desc 'Recreate issue search index'
  task recreate_issues_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Issue.__elasticsearch__.client.indices.delete index: "issues-#{Rails.env}" rescue nil
    Issue.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex the issues search'
  task reindex_issues: [:environment, :recreate_issues_index] do
    Issue.indexable.import
  end

  desc 'Recreate the search index'
  task recreate_projects_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Project.__elasticsearch__.client.indices.delete index: "projects-#{Rails.env}" rescue nil
    Project.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex the search'
  task reindex_projects: [:environment, :recreate_projects_index] do
    Project.import query: -> { indexable }
  end
end
