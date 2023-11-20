# frozen_string_literal: true

class BackfillAddLiftedToProject < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Project.in_batches do |relation|
      relation.update_all lifted: false
      sleep(0.01)
    end
  end

  def down
    # no-op
  end
end
