# frozen_string_literal: true

class InstallAudited < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def self.up
    create_table :audits do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :associated_id, :integer
      t.column :associated_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :text
      t.column :version, :integer, default: 0
      t.column :comment, :string
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :created_at, :datetime
    end

    add_index :audits, %i[auditable_type auditable_id version], name: "auditable_index", algorithm: :concurrently
    add_index :audits, %i[associated_type associated_id], name: "associated_index", algorithm: :concurrently
    add_index :audits, %i[user_id user_type], name: "user_index", algorithm: :concurrently
    add_index :audits, :request_uuid, algorithm: :concurrently
    add_index :audits, :created_at, algorithm: :concurrently
  end

  def self.down
    drop_table :audits
  end
end
