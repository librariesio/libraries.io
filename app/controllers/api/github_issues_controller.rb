class Api::GithubIssuesController < Api::ApplicationController
  def help_wanted
    @search = paginate GithubIssue.search('', filters: {
      license: current_license,
      language: current_language,
      labels: (['help wanted'] + [params[:labels]]).compact
    })
    @github_issues = @search.records.includes(:github_repository)
    render json: @github_issues.as_json(only: GithubIssue::API_FIELDS, include: {:github_repository => {only: GithubRepository::API_FIELDS}})
  end

  def first_pull_request
    @search = paginate GithubIssue.first_pr_search('', filters: {
      license: current_license,
      language: current_language,
      labels: params[:labels]
    })
    @github_issues = @search.records.includes(:github_repository)
    render json: @github_issues.as_json(only: GithubIssue::API_FIELDS, include: {:github_repository => {only: GithubRepository::API_FIELDS}})
  end

  private

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end
end
