# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  def recommended_projects
    projects = Project.where(id: recommended_project_ids).order(Arel.sql("position(','||projects.id::text||',' in '#{recommended_project_ids.join(',')}'), projects.rank DESC NULLS LAST"))
    projects = unfiltered_recommendations if projects.empty?
    projects.where.not(id: already_watching_ids).maintained.includes(:repository, :versions)
  end

  def recommended_project_ids
    Rails.cache.fetch "recommendations:#{id}", expires_in: 1.day do
      ids = favourite_recommendation_ids + most_depended_on_recommendation_ids + most_watched_recommendation_ids
      sort_array_by_frequency(ids)
    end
  end

  def already_watching_ids
    subscribed_projects.pluck(:id)
  end

  def recommendation_filter(scope)
    filtered = scope.maintained.where.not(id: already_watching_ids)
    filtered = filtered.where("lower(projects.platform) IN (?)", favourite_platforms.map(&:downcase)) if favourite_platforms.any?
    filtered = filtered.where("lower(projects.language) IN (?)", favourite_languages.map(&:downcase)) if favourite_languages.any?
    filtered.pluck(:id)
  end

  def favourite_recommendation_ids
    return [] if repository_user.nil?

    recommendation_filter repository_user.favourite_projects.limit(100)
  end

  def most_depended_on_recommendation_ids
    recommendation_filter Project.most_dependents.limit(50)
  end

  def most_watched_recommendation_ids
    recommendation_filter Project.most_watched.limit(50)
  end

  def unfiltered_recommendations
    ids = Project.maintained.most_dependents.limit(50).pluck(:id) + Project.maintained.most_watched.limit(50).pluck(:id)
    Project.where(id: sort_array_by_frequency(ids)).order(Arel.sql("projects.rank DESC NULLS LAST")).maintained
  end

  def favourite_platforms
    favourite_languages.map { |lang| platform_language_mapping[lang.to_sym] }.compact.uniq
  end

  def favourite_languages(_limit = 3)
    @favourite_languages ||= begin
      # your github Repositories
      languages = all_repositories.pluck(:language).compact

      # repositories you've contributed to
      languages += repository_user.contributed_repositories.pluck(:language).compact if repository_user.present?

      # Repositories your subscribed to (twice to bump those languages)
      languages += subscribed_projects.pluck(:language).compact + subscribed_projects.pluck(:language).compact

      sort_array_by_frequency(languages) || []
    end
  end

  def sort_array_by_frequency(arr)
    arr.each_with_object(Hash.new(0)) do |v, h|
      h[v] += 1
    end.sort_by { |_k, v| -v }.map(&:first)
  end

  def platform_language_mapping
    {
      'Go': "Go",
      'JavaScript': "NPM",
      'Objective-C': "CocoaPods",
      'Swift': "SwiftPM",
      'HTML': "Bower",
      'CSS': "Bower",
      'CoffeeScript': "NPM",
      'TypeScript': "NPM",
      'LiveScript': "NPM",
      'Ruby': "Rubygems",
      'PHP': "Packagist",
      'Java': "Maven",
      'Python': "Pypi",
      'Scala': "Maven",
      'C#': "Nuget",
      'Clojure': "Clojars",
      'Perl': "CPAN",
      'Haskell': "Hackage",
      'Rust': "Cargo",
      'Dart': "Pub",
      'Elm': "Elm",
      'R': "CRAN",
      'Elixir': "Hex",
      'Erlang': "Hex",
      'Julia': "Julia",
      'D': "Dub",
      'Nimrod': "Nimble",
    }
  end
end
