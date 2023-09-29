# frozen_string_literal: true

module PackageManager
  class NuGet
    module SemverRegistrationApiHasItems
      def releases
        # Existing code using this path only uses the first set of
        # items in this API response.
        raw_releases.map do |details|
          catalog_entry = details["catalogEntry"]

          dependencies = catalog_entry
            .fetch("dependencyGroups", [])
            .flat_map { |d| d["dependencies"] }
            .compact
            .map do |d|
              SemverRegistrationProjectDependency.new(
                name: d["id"],
                requirements: parse_requirements(d["range"])
              )
            end

          catalog_entry_deprecation = catalog_entry["deprecation"]

          deprecation = if catalog_entry_deprecation
                          SemverRegistrationProjectDeprecation.new(
                            message: catalog_entry_deprecation["message"] ||
                              catalog_entry_deprecation["reasons"]&.join(", "),
                            alternate_package: catalog_entry_deprecation.dig(
                              "alternatePackage", "id"
                            )
                          )
                        end

          SemverRegistrationProjectRelease.new(
            published_at: Time.parse(catalog_entry["published"]),
            version_number: catalog_entry["version"],
            project_url: catalog_entry["projectUrl"],
            deprecation: deprecation,
            description: catalog_entry["description"],
            summary: catalog_entry["summary"],
            tags: Array(catalog_entry["tags"]).sort,
            licenses: catalog_entry["licenseExpression"],
            license_url: catalog_entry["licenseUrl"],
            dependencies: dependencies
          )
        end.sort
      end

      private

      def parse_requirements(range)
        return unless range.present?

        parts = range[1..-2].split(",")
        requirements = []
        low_bound = range[0]
        high_bound = range[-1]
        low_number = parts[0].strip
        high_number = parts[1].try(:strip)

        # lowest
        low_sign = low_bound == "[" ? ">=" : ">"
        high_sign = high_bound == "]" ? "<=" : "<"

        # highest
        if high_number != low_number
          requirements << "#{low_sign} #{low_number}" if low_number.present?
          requirements << "#{high_sign} #{high_number}" if high_number.present?
        elsif high_number == low_number
          requirements << "= #{high_number}"
        elsif low_number.present?
          requirements << "#{low_sign} #{low_number}"
        end
        requirements << ">= 0" if requirements.empty?
        requirements.join(" ")
      end
    end
  end
end
