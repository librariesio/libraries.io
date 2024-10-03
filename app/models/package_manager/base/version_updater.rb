# frozen_string_literal: true

module PackageManager
  class Base
    class VersionUpdater
      def initialize(
        project:,
        api_version_to_upsert:,
        new_repository_source:,
        preloaded_db_versions:
      )
        @project = project
        @api_version_to_upsert = api_version_to_upsert
        @new_repository_source = new_repository_source
        @preloaded_db_versions = preloaded_db_versions
      end

      def upsert_version_for_project!
        db_project_version.skip_save_project = true
        db_project_version.assign_attributes(@api_version_to_upsert.to_version_model_attributes)

        if @new_repository_source
          existing_repository_sources = Set.new(db_project_version.repository_sources)
          existing_repository_sources << @new_repository_source
          db_project_version.repository_sources = existing_repository_sources.to_a
        end

        db_project_version.save!
      # It's possible for this same code to be running, at the same time, on
      # the same version, where both are trying to add a new version at the
      # same time. These rescues catch those possiblities so that we can be
      # alerted when they're happening.
      rescue ActiveRecord::RecordNotUnique => e
        # Until all package managers support version-specific updates, we'll have this race condition
        # of 2+ jobs trying to add versions at the same time.
        if e.message =~ /PG::UniqueViolation/
          Rails.logger.info "[DUPLICATE VERSION 1] platform=#{@project.platform} name=#{@project.name} version=#{@api_version_to_upsert.version_number}"
        else
          raise e
        end
      rescue ActiveRecord::RecordInvalid => e
        # Until all package managers support version-specific updates, we'll have this race condition
        # of 2+ jobs trying to add versions at the same time.
        if e.message =~ /Number has already been taken/
          Rails.logger.info "[DUPLICATE VERSION 2] platform=#{@project.platform} name=#{@project.name} version=#{@api_version_to_upsert.version_number}"
        else
          raise e
        end
      end

      private

      def db_project_version
        @db_project_version ||= @preloaded_db_versions.find { |v| v.number == @api_version_to_upsert.version_number } ||
                                @project.versions.new(number: @api_version_to_upsert.version_number)
      end
    end
  end
end
