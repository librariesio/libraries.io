# frozen_string_literal: true
class AddDependentsCountIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, :dependents_count
  end
end
