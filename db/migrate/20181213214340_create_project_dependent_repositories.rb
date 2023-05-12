# frozen_string_literal: true

class CreateProjectDependentRepositories < ActiveRecord::Migration[5.2]
  def change
    create_view :project_dependent_repositories, materialized: true
    add_index :project_dependent_repositories, %i[project_id rank stargazers_count],
              name: "index_project_dependent_repos_on_rank",
              order: { project_id: :asc, rank: "DESC NULLS LAST", stargazers_count: :desc }
    add_index :project_dependent_repositories, %i[project_id repository_id], unique: true,
                                                                             name: "index_project_dependent_repos_on_proj_id_and_repo_id"
  end
end
