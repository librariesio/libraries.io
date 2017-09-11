class CreateSimilarNames < ActiveRecord::Migration[5.0]
  def change
    create_table :similar_names do |t|
      t.references :project, foreign_key: true
      t.string :matches, array: true, default: []

      t.timestamps
    end
  end
end
