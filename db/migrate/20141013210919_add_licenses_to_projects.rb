class AddLicensesToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :licenses, :string
  end
end
