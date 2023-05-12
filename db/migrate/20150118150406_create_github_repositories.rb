# frozen_string_literal: true

class CreateGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    create_table :github_repositories do |t|
      t.integer :project_id
      t.string :full_name
      t.string :owner_id
      t.string :description
      t.boolean :fork
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :pushed_at
      t.string :homepage
      t.integer :size
      t.integer :stargazers_count
      t.string :language
      t.boolean :has_issues
      t.boolean :has_wiki
      t.boolean :has_pages
      t.integer :forks_count
      t.string :mirror_url
      t.integer :open_issues_count
      t.string :default_branch
      t.integer :subscribers_count

      t.timestamps null: false
    end
  end
end
