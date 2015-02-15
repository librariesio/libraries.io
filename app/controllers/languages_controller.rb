class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages
  end

  def show
    find_language
    @updated = Project.search('*', filters: { language: @language }, sort: 'updated_at').records.first(5)
    @created = Project.search('*', filters: { language: @language }, sort: 'created_at').records.first(5)
    @popular = Project.popular(filters: { language: @language }).first(5)
    @licenses = Project.popular_licenses(filters: { language: @language }).first(8)
    @platforms = Project.popular_platforms(filters: { language: @language }).first(10)
  end

  def find_language
    @language = GithubRepository.where('lower(language) = ?', params[:id].downcase).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
