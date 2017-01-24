class AddRepositoryIdIndex < ActiveRecord::Migration
  def change
    add_index(:projects, :repository_id)
  end
end
