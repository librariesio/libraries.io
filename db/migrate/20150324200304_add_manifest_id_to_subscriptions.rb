# frozen_string_literal: true
class AddManifestIdToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :manifest_id, :integer
  end
end
