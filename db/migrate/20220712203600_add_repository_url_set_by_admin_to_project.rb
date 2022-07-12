class AddRepositoryUrlSetByAdminToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :repository_url_set_by_admin, :boolean, default: false
  end
end
