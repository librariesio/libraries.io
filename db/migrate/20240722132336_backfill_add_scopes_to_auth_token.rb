# frozen_string_literal: true

class BackfillAddScopesToAuthToken < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    AuthToken.unscoped.in_batches do |relation|
      relation.update_all scopes: []
      sleep(0.01)
    end
  end
end
