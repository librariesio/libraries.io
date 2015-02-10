class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages
  end

  def show
    find_language
    scope = Project.language(@language)
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = Project.popular(filters: { language: @language }).first(5)
    @licenses = Project.popular_licenses(filters: { language: @language }).first(8)
  end

  def find_language
    @language = GithubRepository.where('language ILIKE ?', params[:id]).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
