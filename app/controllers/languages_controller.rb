class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages(:facet_limit => 120)
  end

  def show
    find_language
    @updated = Project.search('*', filters: { language: @language }, sort: 'updated_at').records.includes(:versions).first(5)
    @created = Project.search('*', filters: { language: @language }, sort: 'created_at').records.includes(:versions).first(5)
    @color = Languages::Language[@language].try(:color)
  end

  def find_language
    @language = GithubRepository.where('lower(language) = ?', params[:id].downcase).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
