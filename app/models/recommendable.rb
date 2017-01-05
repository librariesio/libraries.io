module Recommendable
  extend ActiveSupport::Concern

  def recommended_projects
    projects = Project.where(id: recommended_project_ids).order("position(','||projects.id::text||',' in '#{recommended_project_ids.join(',')}'), projects.rank DESC")
    projects = unfiltered_recommendations if projects.empty?
    projects.where.not(id: already_watching_ids).maintained.includes(:github_repository, :versions)
  end

  def recommended_project_ids
    Rails.cache.fetch "recommendations:#{self.id}", :expires_in => 1.day do
      ids = favourite_recommendation_ids + most_depended_on_recommendation_ids + most_watched_recommendation_ids
      ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|_k,v| -v}.map(&:first)
    end
  end

  def already_watching_ids
    subscribed_projects.pluck(:id)
  end

  def recommendation_filter(scope)
    filtered = scope.maintained.where.not(id: already_watching_ids)
    filtered = filtered.where('lower(projects.platform) IN (?)', favourite_platforms.map(&:downcase)) if favourite_platforms.any?
    filtered = filtered.where('lower(projects.language) IN (?)', favourite_languages.map(&:downcase)) if favourite_languages.any?
    filtered.pluck(:id)
  end

  def favourite_recommendation_ids
    return [] if github_user.nil?
    recommendation_filter github_user.favourite_projects.limit(100)
  end

  def most_depended_on_recommendation_ids
    recommendation_filter Project.most_dependents.limit(50)
  end

  def most_watched_recommendation_ids
    recommendation_filter Project.most_watched.limit(50)
  end

  def unfiltered_recommendations
    ids = Project.maintained.most_dependents.limit(50).pluck(:id) + Project.maintained.most_watched.limit(50).pluck(:id)
    ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|_k,v| -v}.map(&:first)
    Project.where(id: ids).order('projects.rank DESC').maintained
  end

  def favourite_platforms
    favourite_languages.map{|lang| platform_language_mapping[lang.to_sym] }.compact.uniq
  end

  def favourite_languages(limit = 3)
    @favourite_languages ||= begin
      # your github Repositories
      languages = all_github_repositories.pluck(:language).compact

      # repositories you've contributed to
      languages += github_user.contributed_repositories.pluck(:language).compact if github_user.present?

      # Repositories your subscribed to (twice to bump those languages)
      languages += subscribed_projects.pluck(:language).compact + subscribed_projects.pluck(:language).compact

      languages = languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|_k,v| -v}.first(limit).map(&:first)
      languages ||= []
    end
  end

  def platform_language_mapping
    {
      'Go': 'Go',
      'JavaScript': 'NPM',
      'Objective-C': 'CocoaPods',
      'Swift': 'SwiftPM',
      'HTML': 'Bower',
      'CSS': 'Bower',
      'CoffeeScript': 'NPM',
      'TypeScript': 'NPM',
      'LiveScript': 'NPM',
      'Ruby': 'Rubygems',
      'PHP': 'Packagist',
      'Java': 'Maven',
      'Python': 'Pypi',
      'Scala': 'Maven',
      'C#': 'Nuget',
      'Clojure': 'Clojars',
      'Perl': 'CPAN',
      'Haskell': 'Hackage',
      'Rust': 'Cargo',
      'Emacs Lisp': 'Emacs',
      'Dart': 'Pub',
      'Elm': 'Elm',
      'R': 'CRAN',
      'Elixir': 'Hex',
      'Erlang': 'Hex',
      'Julia': 'Julia',
      'D': 'Dub',
      'Nimrod': 'Nimble'
    }
  end
end
