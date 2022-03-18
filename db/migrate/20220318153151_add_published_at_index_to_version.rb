class AddPublishedAtIndexToVersion < ActiveRecord::Migration[5.2]
  def change
    add_index :versions, [:project_id, :published_at]
  end
end
