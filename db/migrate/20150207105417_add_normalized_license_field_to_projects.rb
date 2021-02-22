# frozen_string_literal: true
class AddNormalizedLicenseFieldToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :normalized_licenses, :string, array: true, default: []
  end
end
