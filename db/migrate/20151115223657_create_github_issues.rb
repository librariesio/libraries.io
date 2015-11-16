class CreateGithubIssues < ActiveRecord::Migration
  def change
    create_table :github_issues do |t|
      t.integer :github_repository_id
      t.integer :github_id
      t.integer :number
      t.string :state
      t.string :title
      t.text :body
      t.integer :github_user_id
      t.boolean :locked
      t.integer :comments_count
      t.datetime :closed_at
      t.string :labels, :string, array: true, default: []

      t.timestamps null: false
    end
  end
end
