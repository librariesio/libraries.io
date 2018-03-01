class AddDetailsToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :description, :text
    add_column :projects, :keywords, :string
    add_column :projects, :homepage, :string
  end
end
