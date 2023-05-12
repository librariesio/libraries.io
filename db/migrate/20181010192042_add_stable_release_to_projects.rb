# frozen_string_literal: true

class AddStableReleaseToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :latest_stable_release_number, :string
    add_column :projects, :latest_stable_release_published_at, :datetime
  end
end
