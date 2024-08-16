# frozen_string_literal: true

module PackageManager
  class Base
    # This builder class only exists to ensure we have a defined set
    # of keys that we allow PackageManager::Base.mapping() to return.
    class MappingBuilder
      MISSING = Object.new

      def self.build_hash(name:, description:, repository_url:, homepage: MISSING, keywords_array: MISSING, licenses: MISSING, versions: MISSING)
        hash = {
          name: name,
          description: description,
          repository_url: repository_url,
        }

        hash[:homepage] = homepage if homepage != MISSING
        hash[:keywords_array] = keywords_array if keywords_array != MISSING
        hash[:licenses] = licenses if licenses != MISSING
        hash[:versions] = versions if versions != MISSING

        # Clean up any string values
        hash.transform_values { |val| val.is_a?(String) ? StringUtils.strip_null_bytes(val) : val }
      end
    end
  end
end
