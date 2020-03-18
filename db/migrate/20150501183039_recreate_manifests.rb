# frozen_string_literal: true

class RecreateManifests < ActiveRecord::Migration[5.0]
  def change
    drop_table :manifests
    remove_column :subscriptions, :manifest_id

    create_table :manifests do |t|
      t.integer :github_repostory_id
      t.string :name
      t.string :path
      t.string :sha
      t.string :branch

      t.timestamps null: false
    end
  end
end
