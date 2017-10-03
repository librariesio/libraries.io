class CreateSupportEvidences < ActiveRecord::Migration[5.0]
  def change
    create_table :support_evidences do |t|
      t.string :currency
      t.integer :amount
      t.string :description
      t.string :source_url
      t.datetime :published_at
      t.references :user, index: true
      t.references :support, index: true
      t.string :kind

      t.timestamps
    end
  end
end
