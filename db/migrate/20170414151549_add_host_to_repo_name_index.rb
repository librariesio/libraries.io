class AddHostToRepoNameIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :repositories, name: :index_github_repositories_on_lowercase_full_name
    add_index :repositories, [:host_type, :full_name], unique: true, case_sensitive: false
  end
end
