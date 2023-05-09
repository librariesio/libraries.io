# frozen_string_literal: true

module Releaseable
  def to_s
    number
  end

  def semantic_version
    @semantic_version ||= begin
      Semantic::Version.new(clean_number)
    rescue ArgumentError
      nil
    end
  end

  def greater_than_1?
    return nil unless follows_semver?

    begin
      SemanticRange.gte(clean_number, "1.0.0")
    rescue StandardError
      false
    end
  end

  def stable?
    valid_number? && !prerelease?
  end

  def valid_number?
    !!semantic_version
  end

  def follows_semver?
    @follows_semver ||= valid_number?
  end

  def parsed_number
    @parsed_number ||= semantic_version || number
  end

  def clean_number
    @clean_number ||= (SemanticRange.clean(number) || number)
  end
end
