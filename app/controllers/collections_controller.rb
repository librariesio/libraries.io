class CollectionsController < ApplicationController
  def index
    @languages = Project.popular_languages.first(28).map(&:term)
  end

  def show
    @search = Project.search(params[:keyword], {filters: {language: [params[:language]]}}).paginate(page: page_number, per_page: per_page_number)
    @projects = @search.records.includes(:github_repository, :versions)
  end
end
