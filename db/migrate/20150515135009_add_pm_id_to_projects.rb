class AddPmIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :pm_id, :integer
  end
end
