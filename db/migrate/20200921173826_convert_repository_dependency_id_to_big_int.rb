class ConvertRepositoryDependencyIdToBigInt < ActiveRecord::Migration[5.2]
  # This is a long-running migration so we don't want to do the entire thing in a transaction.
  # disable_ddl_transaction!

  def up
    if ENV['CIRCLE_CI']
      say "Skipping ConvertRepositoryDependencyIdToBigInt migration in Circle. To run, reverse it and run it again in a persistent shell on production."
      return
    end

    @start_time = Time.now

    create_new_table
    create_triggers
    copy_old_to_new
    rename_tables
    delete_triggers
    puts "Done! Archived table is at #{archived_table_name}. Drop table when you have verified the new one is correct."
  end

  def down
    # no-op
  end

  def self.manual_cleanup
    delete_triggers
  end

  private

    def create_new_table
      # JIC renaming indices locks table, we're just going to keep the same names and add a unique suffix.
      index_suffix = @start_time.to_i

      # Clone table and make change: bigserial pkey, instead of serial.
      create_table "repository_dependencies_new", id: :bigserial, force: :cascade do |t|
        t.integer "project_id"
        t.integer "manifest_id"
        t.boolean "optional"
        t.string "project_name"
        t.string "platform"
        t.string "requirements"
        t.string "kind"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.integer "repository_id"
        t.index ["manifest_id"], name: "index_repository_dependencies_on_manifest_id_#{index_suffix}"
        t.index ["project_id"], name: "index_repository_dependencies_on_project_id_#{index_suffix}"
        t.index ["repository_id"], name: "index_repository_dependencies_on_repository_id_#{index_suffix}"
      end
    end

    def rename_tables
      # TODO make sure that lock table is using most restrictive lock mode by default
      say_with_time "Renaming tables (archive will be #{archived_table_name})." do
        connection.execute "begin"
        connection.execute "lock table repository_dependencies, repository_dependencies_new"
        connection.execute "alter table repository_dependencies rename to #{archived_table_name}"
        connection.execute "alter table repository_dependencies_new rename to repository_dependencies"
        connection.execute "commit"
      end
    end

    def copy_old_to_new
      chunk_size = 100_000
      min = connection.select_value("select min(id) from repository_dependencies").to_i
      max = connection.select_value("select max(id) from repository_dependencies").to_i
      current_min = min
      current_max = current_min + chunk_size - 1

      say "Copying old rows to new table: ids #{min} to #{max}, in chunks of #{chunk_size}."
      while current_min < max
        num_rows = connection.update(%Q!
          insert into repository_dependencies_new (id, project_id, manifest_id, optional, project_name, platform, requirements, kind, created_at, updated_at, repository_id)
            select id, project_id, manifest_id, optional, project_name, platform, requirements, kind, created_at, updated_at, repository_id 
            from repository_dependencies
            where repository_dependencies.id between #{ current_min } and #{ current_max }
            on conflict do nothing
        !)
        print "."
        puts " #{((current_min / current_max.to_f) * 100).round}% " if current_min % 10_000_000 
        current_min = current_max + 1
        current_max = current_min + chunk_size - 1
      end
    end

    def create_triggers
      say "Creating insert trigger function"
      connection.execute %Q!CREATE OR REPLACE FUNCTION on_insert_repository_dependencies()  RETURNS TRIGGER LANGUAGE plpgsql AS $$
          BEGIN
            insert into repository_dependencies_new (id, project_id, manifest_id, optional, project_name, platform, requirements, kind, created_at, updated_at, repository_id)
            values (NEW.project_id, NEW.manifest_id, NEW.optional, NEW.project_name, NEW.platform, NEW.requirements, NEW.kind, NEW.created_at, NEW.updated_at, NEW.repository_id)
            on conflict (id) do update
              set id=NEW.id, project_id=NEW.project_id, manifest_id=NEW.manifest_id, optional=NEW.optional, project_name=NEW.project_name, platform=NEW.platform, requirements=NEW.requirements, kind=NEW.kind, created_at=NEW.created_at, updated_at=NEW.updated_at, repository_id=NEW.repository_id;
          END;
          $$!

      say "Creating insert trigger"
      connection.execute "create trigger migration_insert_repository_dependencies after insert on repository_dependencies for each row EXECUTE PROCEDURE on_insert_repository_dependencies()"

      say "Creating update trigger function"
      connection.execute %Q!CREATE OR REPLACE FUNCTION on_update_repository_dependencies() RETURNS TRIGGER LANGUAGE plpgsql AS $$
          BEGIN
            insert into repository_dependencies_new (id, project_id, manifest_id, optional, project_name, platform, requirements, kind, created_at, updated_at, repository_id)
            values (NEW.project_id, NEW.manifest_id, NEW.optional, NEW.project_name, NEW.platform, NEW.requirements, NEW.kind, NEW.created_at, NEW.updated_at, NEW.repository_id)
            on conflict (id) do update
              set id=NEW.id, project_id=NEW.project_id, manifest_id=NEW.manifest_id, optional=NEW.optional, project_name=NEW.project_name, platform=NEW.platform, requirements=NEW.requirements, kind=NEW.kind, created_at=NEW.created_at, updated_at=NEW.updated_at, repository_id=NEW.repository_id;
          END;
          $$!

      say "Creating update trigger"
      connection.execute "create trigger migration_update_repository_dependencies after update on repository_dependencies for each row EXECUTE PROCEDURE on_update_repository_dependencies()"

      # Is it possible in postgres to ignore errors while deleting? (eg ON ERROR)
      say "Creating delete trigger function"
      connection.execute %Q!CREATE OR REPLACE FUNCTION on_delete_repository_dependencies() RETURNS TRIGGER LANGUAGE plpgsql AS $$
        BEGIN
          delete from repository_dependencies_new where repository_dependencies_new.id = OLD.id;
        END;
        $$;!

      say "Creating delete trigger"
      connection.execute "create trigger migration_delete_repository_dependencies after delete on repository_dependencies for each row EXECUTE PROCEDURE on_delete_repository_dependencies()"
    end

    def delete_triggers
      say "Deleting delete trigger"
      connection.execute "drop trigger migration_delete_repository_dependencies ON #{archived_table_name}"
      say "Deleting insert trigger"
      connection.execute "drop trigger migration_insert_repository_dependencies ON #{archived_table_name}"
      say "Deleting update trigger"
      connection.execute "drop trigger migration_update_repository_dependencies ON #{archived_table_name}"
      
      say "Deleting insert trigger functions"
      connection.execute "drop function on_insert_repository_dependencies()"
      say "Deleting update trigger functions"
      connection.execute "drop function on_update_repository_dependencies()"
      say "Deleting delete trigger functions"
      connection.execute "drop function on_delete_repository_dependencies()"
    end

    def archived_table_name
      @archived_table_name ||= "archived_#{ @start_time.strftime "%Y_%m_%d_%H_%M_%S_#{ '%03d' % (@start_time.usec / 1000) }" }_repository_dependencies"[0...64]
    end
end
