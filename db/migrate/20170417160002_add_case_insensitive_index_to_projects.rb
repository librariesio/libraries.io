# frozen_string_literal: true

class AddCaseInsensitiveIndexToProjects < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, "lower(platform), lower(name)", name: "index_projects_on_platform_and_name_lower"
  end
end
