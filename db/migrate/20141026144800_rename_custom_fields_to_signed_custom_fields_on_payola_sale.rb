class RenameCustomFieldsToSignedCustomFieldsOnPayolaSale < ActiveRecord::Migration[5.0]
  def change
    rename_column :payola_sales, :custom_fields, :signed_custom_fields
  end
end
