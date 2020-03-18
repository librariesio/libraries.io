# frozen_string_literal: true

class RenameGithubContributionsTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :github_contributions, :contributions
    rename_column :repositories, :github_contributions_count, :contributions_count
  end
end
