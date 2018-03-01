class AddIncludeBetaToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :include_prerelease, :boolean, default: true
  end
end
