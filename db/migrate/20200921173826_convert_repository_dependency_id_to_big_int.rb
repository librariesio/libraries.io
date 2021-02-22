# frozen_string_literal: true
class ConvertRepositoryDependencyIdToBigInt < ActiveRecord::Migration[5.2]
  def up
    # NB this locks the table, so we're disabling related code temporarily, while it runs.
    change_column :repository_dependencies, :id, :bigint
  end

  def down
    change_column :repository_dependencies, :id, :integer
  end
end
