class AddStableToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :stable, :boolean
    add_column :github_tags, :stable, :boolean
  end
end
