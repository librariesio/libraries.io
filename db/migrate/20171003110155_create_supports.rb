class CreateSupports < ActiveRecord::Migration[5.0]
  def change
    create_table :supports do |t|
      t.string :primary_currency
      t.integer :balance
      t.references :supportable, polymorphic:true, index: true
      t.timestamps
    end
  end
end
