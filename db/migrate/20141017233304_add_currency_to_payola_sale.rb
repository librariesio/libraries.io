# frozen_string_literal: true
class AddCurrencyToPayolaSale < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_sales, :currency, :string
  end
end
