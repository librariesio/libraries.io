# frozen_string_literal: true

class AddRepositoryToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :repository_url, :string
  end
end
