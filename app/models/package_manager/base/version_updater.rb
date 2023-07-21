module PackageManager
  class Base
    class VersionUpdater
      def initialize(
        project:,
        incoming_version:,
        repository_source:
      )
        @project = project
        @incoming_version = incoming_version
        @repository_source = repository_source
      end

      def execute
        db_project_version.skip_save_project = true
        db_project_version.assign_attributes(@incoming_version.to_h)

        if @repository_source
          existing_repository_sources = Set.new(db_project_version.repository_sources)
          existing_repository_sources << @repository_source
          db_project_version.repository_sources = existing_repository_sources.to_a
        end

        db_project_version.save!
      rescue ActiveRecord::RecordNotUnique => e
        # Until all package managers support version-specific updates, we'll have this race condition
        # of 2+ jobs trying to add versions at the same time.
        if e.message =~ /PG::UniqueViolation/
          Rails.logger.info "[DUPLICATE VERSION 1] platform=#{@project.platform} name=#{@project.name} version=#{@incoming_version.number}"
        else
          raise e
        end
      rescue ActiveRecord::RecordInvalid => e
        # Until all package managers support version-specific updates, we'll have this race condition
        # of 2+ jobs trying to add versions at the same time.
        if e.message =~ /Number has already been taken/
          Rails.logger.info "[DUPLICATE VERSION 2] platform=#{@project.platform} name=#{@project.name} version=#{@incoming_version.number}"
        else
          raise e
        end
      end

      private

      def db_project_version
        @db_project_version ||= @project.versions.find_or_initialize_by(number: @incoming_version.number)
      end
    end
  end
end
