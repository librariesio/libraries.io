class GithubIssuesController < ApplicationController
  def index
    @github_issues = GithubIssue.actionable.paginate(page: params[:page])
  end
end
