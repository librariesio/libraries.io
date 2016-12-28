class CreatePayolaAffiliates < ActiveRecord::Migration
  def change
    create_table :payola_affiliates do |t|
      t.string :code
      t.string :email
      t.integer :percent

      t.timestamps
    end
  end
end
