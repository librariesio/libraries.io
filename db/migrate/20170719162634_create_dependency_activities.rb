class CreateDependencyActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :dependency_activities do |t|
      t.references :repository, index: true
      t.references :project, index: true
      t.string :action
      t.string :project_name
      t.string :commit_message
      t.string :requirement
      t.string :kind
      t.string :manifest_path
      t.string :manifest_kind
      t.string :commit_sha
      t.string :platform
      t.string :previous_requirement
      t.string :previous_kind
      t.datetime :committed_at, index: true

      t.timestamps
    end
  end
end
