class AddPlatformToGithubContributions < ActiveRecord::Migration
  def change
    add_column :github_contributions, :platform, :string
  end
end
