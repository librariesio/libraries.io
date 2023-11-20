# frozen_string_literal: true

class AddProjectMaintainedIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :projects,
              %i[platform language id],
              name: "index_projects_on_maintained",
              where: "status in ('Active','Help Wanted') or status is null",
              algorithm: :concurrently
  end
end
