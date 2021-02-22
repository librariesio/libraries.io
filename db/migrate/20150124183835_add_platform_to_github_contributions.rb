# frozen_string_literal: true
class AddPlatformToGithubContributions < ActiveRecord::Migration[5.0]
  def change
    add_column :github_contributions, :platform, :string
  end
end
