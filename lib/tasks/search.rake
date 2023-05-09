# frozen_string_literal: true

namespace :search do
  desc "Reindex everything"
  task reindex_everything: %i[reindex_repos reindex_projects]

  desc "Recreate repo search index"
  task recreate_repos_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    begin
      Repository.__elasticsearch__.client.indices.delete index: "repositories-#{Rails.env}"
    rescue StandardError
      nil
    end
    Repository.__elasticsearch__.create_index! force: true
  end

  desc "Reindex repositories"
  task reindex_repos: %i[environment recreate_repos_index] do
    Repository.indexable.import
  end

  desc "Recreate the search index"
  task recreate_projects_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    begin
      Project.__elasticsearch__.client.indices.delete index: "projects-#{Rails.env}"
    rescue StandardError
      nil
    end
    Project.__elasticsearch__.create_index! force: true
  end

  desc "Reindex projects"
  task reindex_projects: %i[environment recreate_projects_index] do
    Project.import query: -> { indexable }
  end
end
