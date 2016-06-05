class GithubIssuesController < ApplicationController
  def index
    @github_issues = GithubIssue.actionable.includes(:github_repository).order('created_at DESC').paginate(page: params[:page])
  end

  def help_wanted
    @search = GithubIssue.search('', filters: {
      license: current_license,
      language: current_language,
      labels: (['help wanted'] + [params[:labels]]).compact
    }).paginate(page: page_number, per_page: per_page_number)
    @github_issues = @search.records.includes(:github_repository)
  end

  def first_pull_request
    @search = GithubIssue.first_pr_search('', filters: {
      license: current_license,
      language: current_language,
      labels: params[:labels]
    }).paginate(page: page_number, per_page: per_page_number)
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
