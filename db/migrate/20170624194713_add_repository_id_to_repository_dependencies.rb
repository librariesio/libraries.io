class AddRepositoryIdToRepositoryDependencies < ActiveRecord::Migration[5.0]
  def change
    add_column :repository_dependencies, :repository_id, :integer

    RepositoryDependency.find_each do |dependency|
      dependency.repository_id = dependency.manifest.repository.id
      dependency.save!
    end
  end
end
