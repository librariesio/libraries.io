# frozen_string_literal: true

class CreatePayolaSales < ActiveRecord::Migration[5.0]
  def change
    create_table :payola_sales do |t|
      t.string   "email",         limit: 191
      t.string   "guid",          limit: 191
      t.integer  "product_id"
      t.string   "product_type", limit: 100
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "state"
      t.string   "stripe_id"
      t.string   "stripe_token"
      t.string   "card_last4"
      t.date     "card_expiration"
      t.string   "card_type"
      t.text     "error"
      t.integer  "amount"
      t.integer  "fee_amount"
      t.integer  "coupon_id"
      t.boolean  "opt_in"
      t.integer  "download_count"
      t.integer  "affiliate_id"
      t.text     "customer_address"
      t.text     "business_address"
      t.timestamps
    end

    add_index "payola_sales", ["coupon_id"], name: "index_payola_sales_on_coupon_id", using: :btree
    add_index "payola_sales", %w[product_id product_type], name: "index_payola_sales_on_product", using: :btree
    add_index "payola_sales", ["email"], name: "index_payola_sales_on_email", using: :btree
    add_index "payola_sales", ["guid"], name: "index_payola_sales_on_guid", using: :btree
  end
end
