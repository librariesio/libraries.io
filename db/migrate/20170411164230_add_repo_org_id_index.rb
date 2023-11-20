# frozen_string_literal: true

class AddRepoOrgIdIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :repositories, :repository_organisation_id
  end
end
