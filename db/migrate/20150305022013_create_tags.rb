class CreateTags < ActiveRecord::Migration
  def change
    create_table :github_tags do |t|
      t.integer :repository_id
      t.string :name
      t.string :sha
      t.string :kind
      t.datetime :published_at

      t.timestamps null: false
    end
    add_index :github_tags, :repository_id
    add_index :github_tags, :name
  end
end
