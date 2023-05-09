# frozen_string_literal: true

class CreatePayolaCoupons < ActiveRecord::Migration[5.0]
  def change
    create_table :payola_coupons do |t|
      t.string :code
      t.integer :percent_off

      t.timestamps
    end
  end
end
