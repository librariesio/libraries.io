# frozen_string_literal: true

class AddTimestampsToDependencies < ActiveRecord::Migration[5.0]
  def change
    change_table(:dependencies, &:timestamps)
  end
end
