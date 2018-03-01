class AddRateLimitToApiKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :rate_limit, :integer, default: 60
  end
end
