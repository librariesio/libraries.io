class AddCurrencyToPayolaSale < ActiveRecord::Migration
  def change
    add_column :payola_sales, :currency, :string
  end
end
