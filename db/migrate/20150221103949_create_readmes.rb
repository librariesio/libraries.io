class CreateReadmes < ActiveRecord::Migration
  def change
    create_table :readmes do |t|
      t.integer :github_repository_id
      t.text :html_body

      t.timestamps null: false
    end
    add_index(:readmes, :github_repository_id)
  end
end
