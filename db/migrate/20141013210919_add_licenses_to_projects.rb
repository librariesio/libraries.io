class AddLicensesToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :licenses, :string
  end
end
