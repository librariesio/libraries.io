# frozen_string_literal: true

class AddProjectsIndexLanguagesLicenses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :projects, "lower(language)", algorithm: :concurrently
    add_index :projects, :normalized_licenses, using: "gin", algorithm: :concurrently
  end
end
