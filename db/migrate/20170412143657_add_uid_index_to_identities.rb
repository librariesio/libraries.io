# frozen_string_literal: true

class AddUidIndexToIdentities < ActiveRecord::Migration[5.0]
  def change
    add_index :identities, :uid
  end
end
