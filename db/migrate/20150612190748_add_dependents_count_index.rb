class AddDependentsCountIndex < ActiveRecord::Migration
  def change
    add_index :projects, :dependents_count
  end
end
