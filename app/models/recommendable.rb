module Recommendable
  extend ActiveSupport::Concern

  def recommended_projects

    Project.where(id: recommended_project_ids)
  end

  def recommended_project_ids
    ids = favourite_recommendation_ids + most_depended_on_recommendation_ids + most_watched_recommendation_ids
    ids.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|k,v| -v}.map(&:first)
  end

  def already_watching_ids
    subscribed_projects.pluck(:id)
  end

  def recommendation_filter(scope)
    scope.where('lower(projects.language) IN (?)', favourite_languages).where.not(id: already_watching_ids).pluck(:id)
  end

  def favourite_recommendation_ids
    recommendation_filter favourite_projects
  end

  def most_depended_on_recommendation_ids
    recommendation_filter Project.most_dependents
  end

  def most_watched_recommendation_ids
    recommendation_filter Project.most_watched
  end

  def favourite_languages(limit = 2)
    all_languages = (github_repositories.where('pushed_at > ?', 1.years.ago).pluck(:language) + subscribed_projects.pluck(:language)).compact
    all_languages = github_repositories.pluck(:language) if all_languages.empty?
    all_languages.inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|k,v| -v}.first(limit).map(&:first).map(&:downcase)
  end
end
