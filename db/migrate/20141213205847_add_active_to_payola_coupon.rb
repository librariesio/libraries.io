class AddActiveToPayolaCoupon < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_coupons, :active, :boolean, default: true
  end
end
