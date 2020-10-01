# frozen_string_literal: true

class BackfillAddSourcesToVersions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Version.unscoped.in_batches do |relation|
      relation.update_all sources: []
      sleep(0.01)
    end
  end
end
