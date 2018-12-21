class AddHostToRepoNameIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :repositories, name: :index_github_repositories_on_lowercase_full_name
    add_index :repositories, 'lower(host_type), lower(full_name)', unique: true
  end
end
