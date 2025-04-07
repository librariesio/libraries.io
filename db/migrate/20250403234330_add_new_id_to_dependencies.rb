# frozen_string_literal: true

class AddNewIdToDependencies < ActiveRecord::Migration[7.1]
  def change
    # Step 1: Add the new uuid column without a default value
    add_column :dependencies, :id_new, :uuid

    # Step 2: Add a default value for new rows
    change_column_default :dependencies, :id_new, from: nil, to: "gen_random_uuid()"
  end
end
