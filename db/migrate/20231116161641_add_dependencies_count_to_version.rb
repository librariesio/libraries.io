class AddDependenciesCountToVersion < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :dependencies_count, :integer
  end
end
