class GithubIssuesController < ApplicationController
  def index
    @github_issues = GithubIssue.actionable.includes(:github_repository).order('created_at DESC').paginate(page: params[:page])
  end

  def help_wanted
    search_issues((['help wanted'] + [params[:labels]]).compact)
  end

  def first_pull_request
    first_pull_request_issues(params[:labels])
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @github_issues = @search.records.includes(:github_repository).sort_by { |u| indexes[u.id] }
  end

  private

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end
end
