# frozen_string_literal: true
class CreateManifests < ActiveRecord::Migration[5.0]
  def change
    create_table :manifests do |t|
      t.integer :user_id
      t.string :name
      t.string :file_name
      t.string :url
      t.text :contents

      t.timestamps null: false
    end
  end
end
