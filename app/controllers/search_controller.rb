class SearchController < ApplicationController
  def index
    @query = params[:q]
    @search = Project.search(params[:q], filters: {
      platform: current_platform,
      normalized_licenses: current_license,
      language: current_language,
      keywords_array: params[:keywords]
    }, sort: format_sort, order: params[:order]).paginate(page: params[:page])
    @suggestion = @search.response.suggest.did_you_mean.first
    @projects = @search.records.includes(:github_repository)
    @title = page_title
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  def current_platform
    Download.format_name(params[:platforms])
  end

  def current_language
    Languages::Language[params[:languages]].to_s if params[:languages].present?
  end

  def current_license
    Spdx.find(params[:licenses]).try(:id) if params[:licenses].present?
  end

  def format_sort
    return nil unless params[:sort].present?
    allowed_sorts.include? params[:sort] ? params[:sort] : nil
  end

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'latest_release_published_at', 'created_at']
  end

  def page_title
    return "Search for #{params[:q]} - Libraries" if params[:q].present?

    modifiers = []
    modifiers << current_license if current_license.present?
    modifiers << current_platform if current_platform.present?
    modifiers << current_language if current_language.present?
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
