class AddDetailsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :description, :text
    add_column :projects, :keywords, :string
    add_column :projects, :homepage, :string
  end
end
