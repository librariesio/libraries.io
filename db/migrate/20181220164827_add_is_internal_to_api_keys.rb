# frozen_string_literal: true
class AddIsInternalToApiKeys < ActiveRecord::Migration[5.1]
  def up
    add_column :api_keys, :is_internal, :boolean
    change_column_null :api_keys, :is_internal, false, false
    change_column_default :api_keys, :is_internal, false
  end

  def down
    remove_column :api_keys, :is_internal
  end
end
