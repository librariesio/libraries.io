class AddCaseInsensitiveIndexToProjects < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, [:platform, :name], case_sensitive: false, name: 'index_projects_on_platform_and_name_lower'
  end
end
