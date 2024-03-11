# frozen_string_literal: true

class PackageManager::Go
  class GoMod
    attr_reader :mod_contents

    RETRACT_WITH_PARENS = /^\s*retract\s\((.*?)\)/m.freeze
    RETRACT_WITHOUT_PARENS = /retract\s(.+)/.freeze
    MODULE_REGEX = /module\s+(.+)/.freeze
    LOCAL_FILEPATH_REGEXP = /\.?\.\//.freeze

    def initialize(mod_contents)
      @mod_contents = mod_contents
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

    # Scans contents for retract directives parses their contents
    #
    # @return [Array<String, Array<String, String>>] an array consisting of:
    #   a version number (String) or
    #   a range represented by a two element array: [range_start_number, range_end_number]
    def retracted_version_ranges
      return @retracted_version_ranges if @retracted_version_ranges

      retract_specs = []
      retract_specs.concat stripped_contents.scan(RETRACT_WITH_PARENS)
      retract_specs.concat stripped_contents.scan(RETRACT_WITHOUT_PARENS)
      retract_specs = retract_specs.flatten

      @retracted_version_ranges = retract_specs.flat_map do |retract_spec|
        parse_retract(retract_spec)
      end
    end

    def canonical_module_name
      module_line = stripped_contents.lines.find { |line| line.match(MODULE_REGEX) }
      return unless module_line

      module_line.scan(MODULE_REGEX).dig(0, 0)
    end

    def dependencies
      Bibliothecary::Parsers::Go.parse_go_mod(mod_contents)
        .reject { |dep| dep[:name].match?(LOCAL_FILEPATH_REGEXP) }
        .map do |dep|
          {
            # Note that Go "replace" directives would result in :original_requirement and :original_name keys being included
            # here too, but Libraries does not need those (yet?)
            project_name: dep[:name],
            requirements: dep[:requirement],
            kind: dep[:type],
            platform: "Go",
          }
        end
    end

    # Best attempt to remove comments and extraneous whitespace
    def stripped_contents
      @stripped_contents ||= mod_contents
        .to_s
        .lines
        .map { |line| line.gsub(/\/\/.*/, "").strip }
        .reject(&:blank?)
        .join("\r\n")
    end

    def parse_version(substring)
      substring.scan(/(v\d\.\d\.\d(\w|\+|\.|-)*)/).dig(0, 0)
    end

    def parse_retract(retract_spec)
      # retract directives can specify a single version or range
      # or be a line separated list of versions and ranges
      # https://go.dev/ref/mod#go-mod-file-retract
      retract_spec.lines.each_with_object([]) do |line, results|
        if line.match?(/\[.+\]/)
          left, _comma, right = line.partition(",")
          start_range = parse_version(left)
          end_range = parse_version(right)

          results << [start_range, end_range] if start_range && end_range
        else
          single_version = parse_version(line)
          results << single_version if single_version
        end
      end
    end
  end
end
