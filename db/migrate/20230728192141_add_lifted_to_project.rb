class AddLiftedToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :lifted, :boolean, default: false
  end
end
