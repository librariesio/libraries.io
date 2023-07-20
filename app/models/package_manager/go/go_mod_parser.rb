# frozen_string_literal: true

class PackageManager::Go
  class GoModParser
    attr_reader :mod_contents

    RETRACT_WITH_PARENS = /^\s*retract\s\((.*?)\)/m.freeze
    RETRACT_WITHOUT_PARENS = /retract\s(.+)/.freeze
    MODULE_REGEX = /module\s+(.+)/.freeze

    def initialize(mod_contents)
      @mod_contents = mod_contents
    end

    # Scans contents for retract directives parses their contents
    #
    # @return [Array<String, Array<String, String>>] an array consisting of:
    #   a version number (String) or
    #   a range represented by a two element array: [range_start_number, range_end_number]
    def retracted_version_ranges
      return @retracted_version_ranges if @retracted_version_ranges

      retract_specs = []
      retract_specs.concat stripped_contents.scan(RETRACT_WITH_PARENS).flatten
      retract_specs.concat stripped_contents.scan(RETRACT_WITHOUT_PARENS).flatten

      @retracted_version_ranges = retract_specs.flat_map do |retract_spec|
        parse_retract(retract_spec)
      end
    end

    def canonical_module_name
      module_line = stripped_contents.lines.find { |line| line.match(MODULE_REGEX) }

      module_line&.scan(MODULE_REGEX)&.dig(0, 0)
    end

    def dependencies
      Bibliothecary::Parsers::Go.parse_go_mod(mod_contents)
        .map do |dep|
        {
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
