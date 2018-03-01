class CreateProjectSuggestions < ActiveRecord::Migration[5.0]
  def change
    create_table :project_suggestions do |t|
      t.integer :project_id
      t.integer :user_id
      t.string :licenses
      t.string :repository_url
      t.text :notes

      t.timestamps null: false
    end
  end
end
