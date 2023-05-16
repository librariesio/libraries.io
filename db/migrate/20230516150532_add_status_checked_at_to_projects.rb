class AddStatusCheckedAtToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :status_checked_at, :datetime
    add_index :projects, :status_checked_at
  end
end
