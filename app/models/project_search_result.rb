class ProjectSearchResult
  include Status

  attr_reader :language
  attr_reader :platform
  attr_reader :name
  attr_reader :description
  attr_reader :status
  attr_reader :latest_release_number
  attr_reader :versions_count
  attr_reader :latest_release_published_at
  attr_reader :stars
  attr_reader :created_at
  attr_reader :id

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
    DateTime.parse(timestamp) rescue nil
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
    'projects/project'
  end

  def record
    @record ||= Project.find(id)
  end

  def sourcerank_2
    record.sourcerank_2
  end

  def sourcerank_calculator
    SourceRankCalculator.new(record)
  end

  def sourcerank_breakdown
    sourcerank_calculator.breakdown
  end
end
