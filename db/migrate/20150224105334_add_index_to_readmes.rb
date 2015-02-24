class AddIndexToReadmes < ActiveRecord::Migration
  def change
    add_index(:readmes, :created_at)
  end
end
