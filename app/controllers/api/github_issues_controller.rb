class Api::GithubIssuesController < Api::ApplicationController
  def help_wanted
    search_issues(labels: (['help wanted'] + [params[:labels]]).compact)

    render json: @github_issues.as_json(only: GithubIssue::API_FIELDS, include: {:github_repository => {only: GithubRepository::API_FIELDS}})
  end

  def first_pull_request
    first_pull_request_issues(params[:labels])
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
