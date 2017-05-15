class AddSlackColumnsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :slack_api_token, :string
    add_column :users, :slack_channel, :string
  end
end
