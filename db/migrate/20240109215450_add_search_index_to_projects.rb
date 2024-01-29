# frozen_string_literal: true

class AddSearchIndexToProjects < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_index :projects, %q{coalesce("projects"."name"::text, '') gist_trgm_ops}, name: "index_projects_search_on_name", using: :gist, length: 256, algorithm: :concurrently
  end

  def down
    remove_index :projects, name: :index_projects_search_on_name, algorithm: :concurrently, if_exists: true
  end
end
