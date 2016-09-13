class AddRateLimitToApiKeys < ActiveRecord::Migration
  def change
    add_column :api_keys, :rate_limit, :integer, default: 60
  end
end
