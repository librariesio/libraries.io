# frozen_string_literal: true

class AddRepositoryUrls < ActiveRecord::Migration[7.0]
  def change
    add_column :repositories, :code_of_conduct_url, :string
    add_column :repositories, :contribution_guidelines_url, :string
    add_column :repositories, :security_policy_url, :string
    add_column :repositories, :funding_urls, :string, array: true
    change_column_default :repositories, :funding_urls, []
  end
end
