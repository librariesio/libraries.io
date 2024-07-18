# frozen_string_literal: true

class BackfillAddRepositoryFundingUrls < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Repository.unscoped.in_batches do |relation|
      relation.update_all funding_urls: []
      sleep(0.01)
    end
  end
end
