class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages(:facet_limit => 160)
  end

  def show
    find_language
    @updated = Project.search('*', filters: { language: @language }, sort: 'latest_release_published_at').records.includes(:github_repository).first(5)
    @created = Project.search('*', filters: { language: @language }, sort: 'created_at').records.includes(:github_repository).first(5)
    @color = Languages::Language[@language].try(:color)
    @watched = Project.language(@language).most_watched.limit(5)
  end

  def find_language
    @language = GithubRepository.where('lower(language) = ?', params[:id].downcase).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
