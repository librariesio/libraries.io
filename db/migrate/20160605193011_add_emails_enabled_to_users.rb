class AddEmailsEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :emails_enabled, :boolean, default: true
  end
end
