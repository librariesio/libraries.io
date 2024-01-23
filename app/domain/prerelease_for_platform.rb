# frozen_string_literal: true

# This consolidates the prelease checking logic into one place.
# It only checks against specific platforms, not against the
# general cases.
class PrereleaseForPlatform
  PYPI_PRERELEASE = /(a|b|rc|dev)[-_.]?[0-9]*$/.freeze

  def self.prerelease?(version_number:, platform:)
    new(version_number: version_number, platform: platform).prerelease?
  end

  def initialize(version_number:, platform:)
    @version_number = version_number
    @platform = platform.downcase
  end

  # @return [Boolean,Nil] True/False if the version string is a prerelease for
  #                       the given platform, or nil if the platform is not supported.
  def prerelease?
    case @platform
    when "rubygems"
      @version_number.count("a-zA-Z") > 0
    when "pypi"
      @version_number =~ PYPI_PRERELEASE
    end
  end
end
