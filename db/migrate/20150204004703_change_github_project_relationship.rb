class ChangeGithubProjectRelationship < ActiveRecord::Migration
  def change
    remove_column :github_repositories, :project_id
    add_column :projects, :repository_id, :integer
  end
end
