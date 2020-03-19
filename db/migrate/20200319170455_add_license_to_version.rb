class AddLicenseToVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :spdx_expression, :string
    add_column :versions, :original_license_string, :string
  end
end
