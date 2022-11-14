# frozen_string_literal: true

# == Schema Information
#
# Table name: project_dependent_repositories
#
#  rank             :integer
#  stargazers_count :integer
#  project_id       :integer
#  repository_id    :integer
#
# Indexes
#
#  index_project_dependent_repos_on_proj_id_and_repo_id  (project_id,repository_id) UNIQUE
#  index_project_dependent_repos_on_rank                 (project_id,rank DESC NULLS LAST,stargazers_count DESC)
#
class ProjectDependentRepository < ApplicationRecord

  def readonly?
    true
  end
  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end
end
