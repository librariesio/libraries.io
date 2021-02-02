class BadgesController < ApplicationController
  before_action :find_project, only: [:dependent_packages, :dependent_repositories]

  def dependent_packages
    render_badge('Dependent Packages', @project.dependents_count, 'brightgreen')
  end

  def dependent_repositories
    render_badge('Dependent Repos', @project.dependent_repos_count, 'brightgreen')
  end

  private

  def render_badge(title, text, colour)
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    style = params[:style] || 'flat'
    redirect_to "https://img.shields.io/badge/#{title}-#{text}-#{colour}.svg?style=#{style}", status: 302
  end

  def render_error_badge
    redirect_to "https://img.shields.io/badge/Libraries.io-unknown-lightgrey.svg?style=#{style}", status: 302
  end

  def find_project
    @project = Project.visible.platform(params[:platform]).where(name: params[:name]).first
    render_error_badge if @project.nil?
  end
end
