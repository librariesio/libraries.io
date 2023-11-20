# frozen_string_literal: true

class ProjectSearchResult
  include Status

  attr_reader :language, :platform, :name, :description, :status, :latest_release_number, :versions_count, :latest_release_published_at, :stars, :created_at, :id

  def initialize(search_result)
    @language = search_result.language
    @platform = search_result.platform
    @name = search_result.name
    @description = search_result.description
    @status = search_result.status
    @latest_release_number = search_result.latest_release_number
    @versions_count = search_result.versions_count
    @latest_release_published_at = parse_timestamp(search_result.latest_release_published_at)
    @stars = search_result.stars
    @created_at = parse_timestamp(search_result.created_at)
    @id = search_result.id
  end

  def parse_timestamp(timestamp)
    return nil unless timestamp.present?

    begin
      DateTime.parse(timestamp)
    rescue StandardError
      nil
    end
  end

  def color
    Linguist::Language[language].try(:color) || platform_class.try(:color)
  end

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_partial_path
    "projects/project"
  end
end
