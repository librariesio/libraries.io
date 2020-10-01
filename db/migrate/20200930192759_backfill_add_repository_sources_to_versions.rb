# frozen_string_literal: true

class BackfillAddRepositorySourcesToVersions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Version.unscoped.in_batches do |relation|
      relation.update_all repository_sources: []
      sleep(0.01)
    end
  end
end
