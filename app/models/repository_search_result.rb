# frozen_string_literal: true

class RepositorySearchResult
  include Status

  attr_reader :language
  attr_reader :full_name
  attr_reader :host_type
  attr_reader :private
  attr_reader :fork
  attr_reader :description
  attr_reader :created_at
  attr_reader :updated_at
  attr_reader :pushed_at
  attr_reader :status
  attr_reader :license
  attr_reader :stargazers_count
  attr_reader :forks
  attr_reader :id

  def initialize(search_result)
    @language = search_result.language
    @full_name = search_result.full_name
    @host_type = search_result.host_type
    @private = search_result._source["private"]
    @fork = search_result._source["fork"]
    @description = search_result.description
    @created_at = parse_timestamp(search_result.created_at)
    @updated_at = parse_timestamp(search_result.updated_at)
    @pushed_at = parse_timestamp(search_result.pushed_at)
    @status = search_result.status
    @license = search_result.license
    @stargazers_count = search_result.stargazers_count
    @forks = search_result.forks_count
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
    Linguist::Language[language].try(:color)
  end

  def to_param
    {
      host_type: host_type.downcase,
      owner: owner_name,
      name: project_name,
    }
  end

  def owner_name
    full_name.split("/")[0]
  end

  def project_name
    full_name.split("/")[1]
  end

  def private?
    !!private
  end

  def stars
    stargazers_count
  end

  def fork?
    !!@fork
  end

  def to_partial_path
    "repositories/repository"
  end
end
