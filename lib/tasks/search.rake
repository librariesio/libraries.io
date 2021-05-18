# frozen_string_literal: true
namespace :search do
  desc 'Reindex everything'
  task reindex_everything: [:reindex_repos, :recreate_repos_index, :reindex_projects]

  desc 'Recreate repo search index'
  task recreate_repos_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Repository.__elasticsearch__.client.indices.delete index: "repositories-#{Rails.env}" rescue nil
    Repository.__elasticsearch__.create_index! force: true
  end

  desc 'Recreate the search index'
  task recreate_projects_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Project.__elasticsearch__.client.indices.delete index: "projects-#{Rails.env}" rescue nil
    Project.__elasticsearch__.create_index! force: true
  end

  desc 'Reindex projects'
  task reindex_projects: [:environment, :recreate_projects_index] do
    Project.import query: -> { indexable }
  end
end
