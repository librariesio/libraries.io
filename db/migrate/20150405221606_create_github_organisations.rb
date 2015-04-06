class CreateGithubOrganisations < ActiveRecord::Migration
  def change
    create_table :github_organisations do |t|
      t.string :login
      t.integer :github_id
      t.string :name
      t.string :blog
      t.string :email
      t.string :location
      t.string :description

      t.timestamps null: false
    end
  end
end
