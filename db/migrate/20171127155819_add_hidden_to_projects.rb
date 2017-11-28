class AddHiddenToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :hidden, :boolean, default: false
  end
end
