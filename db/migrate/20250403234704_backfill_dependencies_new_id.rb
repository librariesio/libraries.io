# frozen_string_literal: true

class BackfillDependenciesNewId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Step 1: Add a unique index; since all values are null, it should be valid already.
    # This index is needed to make the backfill and the not null constraint efficient.
    # We will need to manually create this on prod before pushing this migration.
    add_index :dependencies, :id_new, algorithm: :concurrently, if_not_exists: true, unique: true

    # Step 2: Fill in all null id_new values with a random uuid using a SQL update statement
    safety_assured do
      reversible do |dir|
        dir.up do
          execute <<-SQL
            UPDATE dependencies
            SET id_new = gen_random_uuid()
            WHERE id_new IS NULL;
          SQL
        end
        dir.down do
          # nothing
        end
      end
    end

    # Step 3: Add a "not null" constraint to id_new column; apparently
    # change_column_null never uses the index to validate, so this is the
    # only option.
    add_check_constraint :dependencies, "id_new IS NOT NULL", name: "dependencies_id_new_null", validate: false
    # should not actually take 2 hours but needs more than a few minutes
    execute("SET statement_timeout = '120min';")
    validate_check_constraint :dependencies, name: "dependencies_id_new_null"
  end
end
