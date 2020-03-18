# frozen_string_literal: true

class IssuesController < ApplicationController
  before_action :ensure_logged_in, only: [:your_dependencies]

  def index
    scope = current_host ? Issue.host(current_host) : Issue.all

    @issues = scope.actionable.includes(:repository).order("created_at DESC").paginate(page: params[:page])
  end

  def help_wanted
    search_issues(labels: (["help wanted"] + [params[:labels]]).compact)
  end

  def first_pull_request
    first_pull_request_issues(params[:labels])
    @issues = @search.records.includes(:repository)
  end

  def your_dependencies
    @repo_ids = current_user.all_dependent_repos.pluck(:id)
    search_issues(repo_ids: @repo_ids)
  end
end
