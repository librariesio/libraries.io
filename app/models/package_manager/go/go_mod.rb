# frozen_string_literal: true

class PackageManager::Go
  class GoMod
    attr_reader :parser

    def initialize(mod_contents)
      @parser = GoModParser.new(mod_contents)
    end

    def retracted_version_ranges
      parser.retracted_version_ranges
    end

    def retracted?(given_version)
      retracted_version_ranges.any? do |version_or_range|
        if version_or_range.is_a?(Array)
          begin_range, end_range = version_or_range
          SemanticRange.gte?(given_version, begin_range) &&
            SemanticRange.lte?(given_version, end_range)
        else
          SemanticRange.satisfies?(given_version, version_or_range)
        end
      end
    end
  end
end
