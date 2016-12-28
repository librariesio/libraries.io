class AddActiveToPayolaCoupon < ActiveRecord::Migration
  def change
    add_column :payola_coupons, :active, :boolean, default: true
  end
end
