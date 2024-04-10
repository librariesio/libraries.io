class BackfillProjectsLatestVersionId < ActiveRecord::Migration[7.0]
  def up
    # This migration has already been run manually in production.
    return if Rails.env.production?

    Project
      .in_batches(of: 10_000) do |projects|
        sql = <<~SQL
          WITH rows_to_update AS (
            SELECT p.id as project_id, latest_version.id as latest_version_id
            FROM projects p
            LEFT JOIN LATERAL (
              SELECT versions.*
              FROM versions 
              WHERE versions.project_id = p.id 
              ORDER BY published_at DESC NULLS LAST, versions.created_at DESC 
              LIMIT 1
            ) as latest_version ON true
            WHERE p.id IN (#{projects.map(&:id).join(",")})
          )
          UPDATE projects
          SET latest_version_id = rows_to_update.latest_version_id
          FROM rows_to_update
          WHERE projects.id = rows_to_update.project_id
        SQL
      
        ActiveRecord::Base.connection.execute(sql)
        print "."
      end
  end

  def down
    # No-op
  end
end
