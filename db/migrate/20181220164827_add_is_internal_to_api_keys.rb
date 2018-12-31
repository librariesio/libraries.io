class AddIsInternalToApiKeys < ActiveRecord::Migration[5.1]
  def change
    add_column :api_keys, :is_internal, :boolean, default: false
  end
end
