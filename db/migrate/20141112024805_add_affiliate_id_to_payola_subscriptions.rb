class AddAffiliateIdToPayolaSubscriptions < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :affiliate_id, :integer
  end
end
