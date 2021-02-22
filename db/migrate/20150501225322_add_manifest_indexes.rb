# frozen_string_literal: true
class AddManifestIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :manifests, :github_repository_id
    add_index :repository_dependencies, :manifest_id
  end
end
