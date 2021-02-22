# frozen_string_literal: true
class AddFieldsToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :name, :string
    add_column :github_users, :company, :string
    add_column :github_users, :blog, :string
    add_column :github_users, :location, :string
  end
end
