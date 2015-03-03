class AddSourceRankToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :rank, :integer, default: 0
  end
end
