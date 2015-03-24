class AddManifestIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :manifest_id, :integer
  end
end
