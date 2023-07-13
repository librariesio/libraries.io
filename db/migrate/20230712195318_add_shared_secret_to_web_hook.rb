class AddSharedSecretToWebHook < ActiveRecord::Migration[5.2]
  def change
    add_column :web_hooks, :shared_secret, :string
  end
end
