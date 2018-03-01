class AddVersionsCounterCacheToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :versions_count, :integer, default: 0, null: false
  end
end
