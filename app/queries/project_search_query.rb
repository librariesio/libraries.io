# frozen_string_literal: true

class ProjectSearchQuery
  attr_reader :term, :platforms, :licenses, :languages, :keywords

  def initialize(term, platforms: [], licenses: [], languages: [], keywords: [])
    @term = term
    @platforms = platforms
    @licenses = licenses
    @languages = languages
    @keywords = keywords
  end

  def results
    @results = Project
      .visible
      .then { |query| filter_platforms(query) }
      .then { |query| filter_languages(query) }
      .then { |query| filter_licenses(query) }
      .then { |query| filter_keywords(query) }
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
end
