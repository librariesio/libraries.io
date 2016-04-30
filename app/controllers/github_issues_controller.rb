class GithubIssuesController < ApplicationController
  def index
    @github_issues = GithubIssue.actionable.includes(:github_repository).paginate(page: params[:page])
  end
end
