# frozen_string_literal: true

class TimelineController < ApplicationController
  before_action :find_project

  def show
    @issues = @project.repository.try(:issues)
    @tags = @project.repository.try(:tags)
    @events = []
    @project.versions.each do |version|
      @events << {
        name: "Version #{version.number} published",
        time: version.published_at,
        icon: "rocket",
      }
    end
    @tags.each do |tag|
      @events << {
        name: "Tag #{tag.name} pushed",
        time: tag.published_at,
        icon: "tag",
      }
    end
    @issues.each do |issue|
      @events << {
        name: "#{issue.pull_request? ? 'Pull Request' : 'Issue'} \"#{issue.title}\" opened",
        time: issue.created_at,
        icon: issue.pull_request? ? "git-pull-request" : "issue-opened",
        color: "text-success",
      }
    end
    @issues.each do |issue|
      next unless issue.closed_at.present?

      @events << {
        name: "#{issue.pull_request? ? 'Pull Request' : 'Issue'} \"#{issue.title}\" #{issue.pull_request? ? 'merged' : 'closed'}",
        time: issue.closed_at,
        icon: issue.pull_request? ? "git-merge" : "issue-closed",
        color: issue.pull_request? ? "text-info" : "text-danger",
      }
    end
    @events = @events.sort_by { |e| e[:time] }.reverse.paginate(page: params[:page], per_page: 30)
  end
end
