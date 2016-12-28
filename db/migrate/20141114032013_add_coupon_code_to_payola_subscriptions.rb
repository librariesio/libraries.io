class AddCouponCodeToPayolaSubscriptions < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :coupon, :string
  end
end
