class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages
  end

  def show
    @language = params[:id]
    scope = Project.language(@language)
    # raise ActiveRecord::RecordNotFound if scope.first.nil?
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = Project.popular(filters: { language: @language }).first(5)
    @licenses = Project.popular_licenses(filters: { language: @language }).first(8)
  end
end
