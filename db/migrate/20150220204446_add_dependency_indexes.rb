# frozen_string_literal: true

class AddDependencyIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index(:dependencies, :version_id)
    add_index(:dependencies, %i[platform project_name])
  end
end
