class AddCustomFieldsToPayolaSale < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_sales, :custom_fields, :text
  end
end
