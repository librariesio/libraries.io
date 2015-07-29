class SearchController < ApplicationController
  def index
    @query = params[:q]
    @search = Project.search(params[:q], filters: {
      platform: params[:platforms],
      normalized_licenses: params[:licenses],
      language: params[:languages],
      keywords_array: params[:keywords]
    }, sort: params[:sort], order: params[:order]).paginate(page: params[:page])
    @suggestion = @search.response.suggest.did_you_mean.first
    @projects = @search.records.includes(:github_repository)
    @title = page_title
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  def page_title
    return "Search for #{params[:q]} - Libraries" if params[:q].present?

    modifiers = []
    modifiers << params[:licenses] if params[:licenses].present?
    modifiers << params[:platforms] if params[:platforms].present?
    modifiers << params[:languages] if params[:languages].present?
    modifiers << params[:keywords] if params[:keywords].present?

    modifier = " #{modifiers.compact.join(' ')} "

    case params[:sort]
    when 'created_at'
      "New#{modifier}Projects - Libraries"
    when 'updated_at'
      "Updated#{modifier}Projects - Libraries"
    when 'latest_release_published_at'
      "Updated#{modifier}Projects - Libraries"
    else
      "Popular#{modifier}Projects - Libraries"
    end
  end
end
