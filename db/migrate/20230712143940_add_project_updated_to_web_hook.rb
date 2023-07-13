class AddProjectUpdatedToWebHook < ActiveRecord::Migration[5.2]
  def change
    add_column :web_hooks, :all_project_updates, :boolean, default: false, null: false
    add_index :web_hooks, ["all_project_updates"]
  end
end
