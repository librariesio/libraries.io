# frozen_string_literal: true
class AddLatestReleaseFieldsToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :latest_release_published_at, :datetime
    add_column :projects, :latest_release_number, :string
  end
end
