class Api::IssuesController < Api::ApplicationController
  def help_wanted
    search_issues(labels: (['help wanted'] + [params[:labels]]).compact)

    render json: @issues
  end

  def first_pull_request
    first_pull_request_issues(params[:labels])
    render json: @issues
  end
end
