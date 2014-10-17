class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.integer :project_id
      t.string :number
      t.datetime :published_at

      t.timestamps
    end
  end
end
