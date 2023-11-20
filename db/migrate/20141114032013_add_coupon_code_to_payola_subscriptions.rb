# frozen_string_literal: true

class AddCouponCodeToPayolaSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_subscriptions, :coupon, :string
  end
end
