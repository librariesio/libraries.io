class AddIncludeBetaToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :include_prerelease, :boolean, default: true
  end
end
