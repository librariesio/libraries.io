# frozen_string_literal: true

module PackageManager
  class Base
    # This class is responsible for taking a project and a list of ApiVersions (aka raw versions mapped
    # to a common set of attributes), and creating Versions for the Project in the database, in a single
    # query. Because we're using +upsert_all()+, Versions that already exist will just be updated.
    # This single query avoids all the N+1s involved in a regular batch insert of Versions that we did in the past.
    class BulkVersionUpdater
      def initialize(db_project:, api_versions:, repository_source_name:)
        @db_project = db_project
        @api_versions = api_versions
        @repository_source_name = repository_source_name
      end

      def run!
        return if @api_versions.empty?

        # create synthetic versions without saving them, so we can get their attributes
        attrs = @api_versions
          .map { |api_version| Version.new(api_version.to_version_model_attributes.merge(project: @db_project)) }
          .each do |v|
            # these will get merged properly in the upsert_all
            v.created_at = v.updated_at = Time.current
            # this value will get merged w/existing in the upsert_all query (see table tests in spec)
            v.repository_sources = @repository_source_name if @repository_source_name
            # from Version#before_save
            v.set_spdx_expression
            # upsert_all doesn't do validation, so ensure they're valid here.
            v.validate!
          end
          .map { |v| v.attributes.without("id") }

        existing_version_ids = @db_project.versions.all.pluck(:id)

        # TODO: we could do this in batches if performance does not scale well with # of versions.
        Version.upsert_all(
          attrs,
          # handles merging any existing repository_sources with new repository_source (see specs for table tests)
          # note that timestamps act slightly differently: we'll use the provided updated_at here if it exists, which
          # might update updated_at even if no attributes changed. Whereas normally with AR's dirty attributes, timestamps
          # wouldn't change unless other attributes had changed during the save.
          on_duplicate: Arel.sql(%!
            status = EXCLUDED.status,
            runtime_dependencies_count = EXCLUDED.runtime_dependencies_count,
            original_license = EXCLUDED.original_license,
            published_at = EXCLUDED.published_at,
            created_at = COALESCE(versions.created_at, EXCLUDED.updated_at),
            updated_at = COALESCE(EXCLUDED.updated_at, versions.updated_at),
            repository_sources = (CASE
            WHEN (versions.repository_sources IS NULL AND EXCLUDED.repository_sources IS NULL)
              THEN NULL
            WHEN (versions.repository_sources @> EXCLUDED.repository_sources)
              THEN versions.repository_sources
            ELSE
              (COALESCE(versions.repository_sources, '[]'::jsonb) || COALESCE(EXCLUDED.repository_sources, '[]'::jsonb))
            END)
          !),
          unique_by: %i[project_id number]
        )

        newly_inserted_versions = @db_project.versions.where.not(id: existing_version_ids)

        # run callbacks manually since upsert_all doesn't run callbacks.
        Version.bulk_after_create_commit(newly_inserted_versions, @db_project)

        self
      end
    end
  end
end
