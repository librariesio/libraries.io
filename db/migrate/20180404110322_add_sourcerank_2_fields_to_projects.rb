class AddSourcerank2FieldsToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :sourcerank_2, :integer, default: 0, null: false
    add_column :projects, :sourcerank_2_last_calculated, :datetime
  end
end
