# frozen_string_literal: true

class AddTokenUpgradeToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :token_upgrade, :boolean
  end
end
