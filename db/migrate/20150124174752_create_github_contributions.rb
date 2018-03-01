class CreateGithubContributions < ActiveRecord::Migration[5.0]
  def change
    create_table :github_contributions do |t|
      t.integer :github_repository_id
      t.integer :github_user_id
      t.integer :count

      t.timestamps null: false
    end
  end
end
