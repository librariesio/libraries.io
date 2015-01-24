class CreateGithubUsers < ActiveRecord::Migration
  def change
    create_table :github_users do |t|
      t.integer :github_id
      t.string :login
      t.string :user_type

      t.timestamps null: false
    end
  end
end
