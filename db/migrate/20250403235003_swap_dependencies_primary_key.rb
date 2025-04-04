class SwapDependenciesPrimaryKey < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          execute <<-SQL
            BEGIN;

            ALTER TABLE dependencies RENAME COLUMN id TO id_old;
            ALTER TABLE dependencies RENAME COLUMN id_new TO id;

            ALTER TABLE dependencies DROP CONSTRAINT dependencies_pkey;
            ALTER TABLE dependencies ADD PRIMARY KEY USING INDEX index_dependencies_on_id_new;

            COMMIT;
          SQL
        end

        dir.down do
          execute <<-SQL
            BEGIN;

            ALTER TABLE dependencies RENAME COLUMN id TO id_new;
            ALTER TABLE dependencies RENAME COLUMN id_old TO id;

            ALTER TABLE dependencies DROP CONSTRAINT dependencies_pkey;
            ALTER TABLE dependencies ADD PRIMARY KEY (id);

            COMMIT;
          SQL
        end
      end
    end
  end
end
