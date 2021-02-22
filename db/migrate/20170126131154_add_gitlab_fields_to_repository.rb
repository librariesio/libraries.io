# frozen_string_literal: true
class AddGitlabFieldsToRepository < ActiveRecord::Migration[5.0]
  def change
    rename_column :repositories, :github_id, :uuid
    add_column :repositories, :host_type, :string
    add_column :repositories, :host_domain, :string
    add_column :repositories, :name, :string
    add_column :repositories, :scm, :string
    add_column :repositories, :fork_policy, :string
    add_column :repositories, :pull_requests_enabled, :string
    add_column :repositories, :logo_url, :string
  end
end
