# frozen_string_literal: true

class AddIndexToDependencies < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # this has already been run on production
    return if Rails.env.production?

    # the covering index (project_id, ((created_at)::date)) already enables this
    remove_index :dependencies, :project_id, if_exists: true, algorithm: :concurrently
    add_index :dependencies, %i[project_id version_id], algorithm: :concurrently
  end
end
