# frozen_string_literal: true

class AddLatestVersionIdToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :latest_version_id, :integer
  end
end
