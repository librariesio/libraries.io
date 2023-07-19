module PackageManager
  class Pypi
    class JsonApiProject
      CLASSIFIER_INACTIVE = "Development Status :: 7 - Inactive"

      def self.request(project_name:)
        data = begin
          ApiService.request_json_with_headers("https://pypi.org/pypi/#{project_name}/json")
        rescue StandardError => e
          Rails.logger.error("Invalid PyPI JSON API Project: #{project_name}: #{e.message}")

          {}
        end

        if data.nil?
          Rails.logger.error("Data is nil for JSON API Project: #{project_name}")

          data = {}
        end

        new(data)
      end

      def initialize(data)
        @data = data
      end

      def license
        @data.dig("info", "license")
      end

      def license_classifiers
        license_classifiers = classifiers.select { |c| c.start_with?("License :: ") }
        license_classifiers.map { |l| l.split(":: ").last }.join(",")
      end

      def name
        @data.dig("info", "name")
      end

      def description
        @data.dig("info", "summary")
      end

      def homepage
        @data.dig("info", "home_page")
      end

      def keywords_array
        Array.wrap(@data.dig("info", "keywords").try(:split, /[\s.,]+/))
      end

      def licenses
        license.presence || license_classifiers
      end

      def repository_url
        ["Source", "Source Code", "Repository", "Code"].filter_map do |field|
          @data.dig("info", "project_urls", field)
        end.first
      end

      def homepage_url
        @data.dig("info", "home_page").presence ||
          @data.dig("info", "project_urls", "Homepage")
      end

      def preferred_repository_url
        RepositoryService.repo_fallback(
          repository_url,
          homepage_url
        )
      end

      def releases
        JsonApiProjectReleases.new(
          @data["releases"].map do |version_number, details|
            first_details = details.first || {}

            JsonApiProjectRelease.new(
              version_number: version_number,
              published_at: release_data_published_at(details),
              is_yanked: first_details["yanked"] == true,
              yanked_reason: first_details["yanked_reason"]
            )
          end
        )
      end

      # Various parts of this process still want raw hashes for a type
      # of data called a "mapping".
      def to_mapping
        {
          name: name,
          description: description,
          homepage: homepage,
          keywords_array: keywords_array,
          licenses: licenses,
          repository_url: preferred_repository_url,
        }
      end

      def deprecated?
        deprecation_status[:is_deprecated]
      end

      def deprecation_message
        deprecation_status[:message]
      end

      private

      def classifiers
        @data.dig("info", "classifiers")
      end

      def deprecation_status
        return @deprecation_status if @deprecation_status

        is_deprecated = false
        message = nil

        latest_stable = releases.reject(&:prerelease?).last

        if latest_stable&.yanked?
          is_deprecated = true
          message = latest_stable.yanked_reason
        elsif classifiers.include?(CLASSIFIER_INACTIVE)
          is_deprecated = true
          message = CLASSIFIER_INACTIVE
        end

        @deprecation_status = {
          is_deprecated: is_deprecated,
          message: message,
        }
      end

      def release_data_published_at(details)
        return nil if details == []

        upload_time = details.dig(0, "upload_time")
        unless upload_time
          Rails.logger.error("PyPI JSON API Project details does not contain upload_time: #{name} (#{upload_time})")
          return nil
        end

        begin
          Time.parse(upload_time)
        rescue ArgumentError => e
          Rails.logger.error("Unable to parse PyPI JSON API Project upload_time: #{name} (#{upload_time}): #{e.message}")

          nil
        end
      end
    end
  end
end
