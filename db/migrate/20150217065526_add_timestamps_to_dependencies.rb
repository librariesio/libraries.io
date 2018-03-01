class AddTimestampsToDependencies < ActiveRecord::Migration[5.0]
  def change
    change_table(:dependencies) { |t| t.timestamps }
  end
end
