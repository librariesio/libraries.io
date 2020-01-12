class AddVersionProjectIdToDependency < ActiveRecord::Migration[5.2]
  def up
    add_column :dependencies, :version_project_id, :integer

    say_with_time "Backfilling Dependency#version_project_id" do
      max_id = Dependency.maximum(:id)
      Dependency.includes(:version).find_in_batches do |b|
        b.each { |dep|
          dep.set_version_project_id
          dep.save!
        }
        last_id = b.last.id
        if last_id % 1_000_000 == 0
          puts "#{((last_id / max_id.to_f) * 100).round(3)}% done."
        end
      end
    end
  end

  def down
    remove_column :dependencies, :version_project_id
  end
end
