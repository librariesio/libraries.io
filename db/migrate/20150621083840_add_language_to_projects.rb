class AddLanguageToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :language, :string
    add_index :projects, :language
  end
end
