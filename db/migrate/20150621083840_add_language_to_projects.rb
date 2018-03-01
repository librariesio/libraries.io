class AddLanguageToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :language, :string
    add_index :projects, :language
  end
end
