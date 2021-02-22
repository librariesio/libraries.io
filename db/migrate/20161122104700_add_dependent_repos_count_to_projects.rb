# frozen_string_literal: true
class AddDependentReposCountToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :dependent_repos_count, :integer
  end
end
