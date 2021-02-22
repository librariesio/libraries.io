# frozen_string_literal: true
class ProjectLicensesNormalized < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :license_normalized, :boolean, default: false
  end
end
