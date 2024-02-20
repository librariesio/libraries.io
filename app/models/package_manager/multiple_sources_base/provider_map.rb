# frozen_string_literal: true

module PackageManager
  class MultipleSourcesBase < Base
    # Given a set of prioritized ProviderInfo objects, determine the most
    # likely upstream package repository for a package. This uses the
    # packages' versions' repository_sources field to
    class ProviderMap
      # @param prioritized_provider_infos [Array(ProviderInfo)] ProviderInfo classes in
      #        the order in which they should be selected for matches.
      def initialize(prioritized_provider_infos:)
        @prioritized_provider_infos = prioritized_provider_infos

        raise "Need exactly one default provider" unless @prioritized_provider_infos.find_all(&:default?).count == 1
      end

      # @param project [Project]
      def providers_for(project:)
        found_providers = project
          .repository_sources
          .map do |source|
            prioritized_provider_infos.find { |provider_info| provider_info.identifier == source }
          end
          .compact

        if found_providers.empty?
          if project.repository_sources.present?
            # If we have removed all possible providers that a version
            # can have, this means that every pacakge will use the
            # default provider, which is probably not what we want.
            # The old providers should be cleaned out of
            # Version#repository_sources first.
            StructuredLog.capture(
              "PROJECT_REPOSITORY_SOURCE_PROVIDERS_MISSING",
              {
                project_id: project.id,
                project_providers: project.repository_sources.join(","),
              }
            )
          end

          [default_provider]
        else
          found_providers
        end
      end

      def default_provider
        prioritized_provider_infos.find(&:default?)
      end

      def preferred_provider_for_project(project:, version: nil)
        db_version = if version
                       project.find_version(version)
                     else
                       project.versions.order(created_at: :desc).first
                     end

        repository_sources = db_version&.repository_sources

        return default_provider unless repository_sources

        best_match = prioritized_provider_infos.find do |provider_info|
          repository_sources.include?(provider_info.identifier)
        end

        best_match || default_provider
      end

      private

      # @!attribute [r] prioritized_provider_infos
      #   ProviderInfo classes in the order in which they should be selected for matches.
      attr_reader :prioritized_provider_infos
    end
  end
end
