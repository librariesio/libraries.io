# frozen_string_literal: true

class AddSearchIndexToProjects < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_index :projects, %q{to_tsvector('simple', coalesce("projects"."description"::text, ''))}, name: "index_projects_search_on_description", using: :gist, length: 512, algorithm: :concurrently
    add_index :projects, %q{coalesce("projects"."name"::text, '') gist_trgm_ops(siglen=512)}, name: "index_projects_search_on_name", using: :gist, algorithm: :concurrently
  end

  def down
    remove_index :projects, name: :index_projects_search_on_name, algorithm: :concurrently, if_exists: true
    remove_index :projects, name: :index_projects_search_on_description, algorithm: :concurrently, if_exists: true
  end
end
