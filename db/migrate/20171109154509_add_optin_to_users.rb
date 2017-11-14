class AddOptinToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :optin, :bool, default: false
  end
end
