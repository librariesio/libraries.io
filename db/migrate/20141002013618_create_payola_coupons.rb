class CreatePayolaCoupons < ActiveRecord::Migration
  def change
    create_table :payola_coupons do |t|
      t.string :code
      t.integer :percent_off

      t.timestamps
    end
  end
end
