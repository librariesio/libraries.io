class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages(:facet_limit => 160)
  end

  def show
    find_language

    @created = Project.language(@language).few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.language(@language).many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @color = Languages::Language[@language].try(:color)
    @watched = Project.language(@language).most_watched.limit(5)
    @popular = Project.language(@language).order('projects.rank DESC').limit(5).includes(:github_repository)
  end

  def find_language
    @language = GithubRepository.where('lower(language) = ?', params[:id].downcase).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
