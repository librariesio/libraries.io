class AddRepositoryToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :repository_url, :string
  end
end
