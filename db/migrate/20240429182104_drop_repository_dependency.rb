# frozen_string_literal: true

class DropRepositoryDependency < ActiveRecord::Migration[7.0]
  def change
    drop_view :project_dependent_repositories, materialized: true
    drop_table :repository_dependencies, if_exists: true
  end
end
