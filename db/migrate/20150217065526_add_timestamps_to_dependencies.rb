class AddTimestampsToDependencies < ActiveRecord::Migration
  def change
    change_table(:dependencies) { |t| t.timestamps }
  end
end
