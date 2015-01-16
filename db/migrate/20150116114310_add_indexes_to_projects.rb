class AddIndexesToProjects < ActiveRecord::Migration
  def change
    add_index :projects, :platform
  end
end
