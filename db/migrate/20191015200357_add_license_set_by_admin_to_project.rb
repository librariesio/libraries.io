# frozen_string_literal: true

class AddLicenseSetByAdminToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :license_set_by_admin, :boolean, default: false
  end
end
