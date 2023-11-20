# frozen_string_literal: true

class AddIndexToRepoDeps < ActiveRecord::Migration[5.0]
  def change
    add_index :repository_dependencies, :project_id
  end
end
