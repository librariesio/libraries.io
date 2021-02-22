# frozen_string_literal: true
class AddEmailsEnabledToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :emails_enabled, :boolean, default: true
  end
end
