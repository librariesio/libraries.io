# frozen_string_literal: true

class AddLiftedToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :lifted, :boolean
    change_column_default :projects, :lifted, false
  end

  def down
    remove_column :projects, :lifted
  end
end
