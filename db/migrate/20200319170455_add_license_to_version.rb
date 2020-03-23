# frozen_string_literal: true

class AddLicenseToVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :spdx_expression, :string
    add_column :versions, :original_license, :jsonb
  end
end
