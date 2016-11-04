class GithubIssuesController < ApplicationController
  def index
    @github_issues = GithubIssue.actionable.includes(:github_repository).order('created_at DESC').paginate(page: params[:page])
  end

  def help_wanted
    search_issues((['help wanted'] + [params[:labels]]).compact)
  end

  def first_pull_request
    search_issues(params[:labels])
    @github_issues = @search.records.includes(:github_repository)
  end

  private

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end
end
