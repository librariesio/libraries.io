class AddCustomFieldsToPayolaSale < ActiveRecord::Migration
  def change
    add_column :payola_sales, :custom_fields, :text
  end
end
