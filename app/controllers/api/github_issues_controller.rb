class Api::GithubIssuesController < Api::ApplicationController
  def help_wanted
    search_issues((['help wanted'] + [params[:labels]]).compact)

    render json: @github_issues.as_json(only: GithubIssue::API_FIELDS, include: {:github_repository => {only: GithubRepository::API_FIELDS}})
  end

  def first_pull_request
    search_issues(params[:labels])
    render json: @github_issues.as_json(only: GithubIssue::API_FIELDS, include: {:github_repository => {only: GithubRepository::API_FIELDS}})
  end

  private

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end

  def search_issues(labels)
    @search = paginate GithubIssue.search('', filters: {
      license: current_license,
      language: current_language,
      labels: labels
    }), page: page_number, per_page: per_page_number
    @github_issues = @search.records.includes(:github_repository)
  end
end
