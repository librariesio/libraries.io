class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.integer :project_id
      t.integer :user_id

      t.timestamps null: false
    end
    add_index(:subscriptions, [:user_id, :project_id])
  end
end
