# frozen_string_literal: true

# ProjectSearchQuery builds a Postgres fulltext search query against Projects
# from the given search parameters
class ProjectSearchQuery
  attr_reader :term, :platforms, :licenses, :languages, :keywords, :sort

  # @param term [String] Text to seach by
  # @param platforms [Array<String>] Limit results to projects on given platforms
  # @param licenses [Array<String>] Limit results to projects with given licenses
  # @param languages [Array<String>] Limit results to projects in given languages
  # @param keywords [Array<String>] Limit results to projects with given keywords
  # @param sort [String] Order results by given attribute instead of relevance
  def initialize(term, platforms: [], licenses: [], languages: [], keywords: [], sort: nil)
    @term = term
    @platforms = platforms
    @licenses = licenses
    @languages = languages
    @keywords = keywords
    @sort = sort
  end

  def results
    @results = Project
      .not_removed
      .then { |query| filter_platforms(query) }
      .then { |query| filter_languages(query) }
      .then { |query| filter_licenses(query) }
      .then { |query| filter_keywords(query) }
      .then { |query| apply_sort(query) }
      .db_search(term)
  end

  private

  def filter_platforms(project_query)
    if platforms.any?
      project_query.platform(platforms)
    else
      project_query
    end
  end

  def filter_languages(project_query)
    if languages.any?
      project_query.where("lower(language)::varchar IN (?)", languages.filter_map(&:downcase))
    else
      project_query
    end
  end

  def filter_licenses(project_query)
    if licenses.any?
      project_query.where("normalized_licenses && ?", licenses.to_postgres_array(omit_quotes: true))
    else
      project_query
    end
  end

  def filter_keywords(project_query)
    if keywords.any?
      project_query.where("keywords_array && ?", keywords.to_postgres_array(omit_quotes: true))
    else
      project_query
    end
  end

  def apply_sort(project_query)
    case sort
    when "rank"
      project_query.order(rank: :desc)
    when "stars"
      project_query.left_joins(:repository).order("repositories.stargazers_count DESC")
    when "dependents_count"
      project_query.order(dependents_count: :desc)
    when "dependent_repos_count"
      project_query.order(dependent_repos_count: :desc)
    when "latest_release_published_at"
      project_query.order(latest_release_published_at: :desc)
    when "contributions_count"
      project_query.left_joins(:repository).order("repositories.contributions_count DESC")
    when "created_at"
      project_query.order(created_at: :desc)
    else
      Rails.logger.info "Ignoring unknown sorting `#{sort}`" unless sort.nil?
      project_query
    end
  end
end
