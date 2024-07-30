# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :ensure_logged_in, only: %i[your_dependent_repos mute unmute
                                            unsubscribe sync]
  before_action :find_project, only: %i[
    about
    dependencies
    dependent_repos
    dependents
    mute
    refresh_stats
    score
    show
    sourcerank
    sync
    tags
    top_dependent_projects
    top_dependent_repos
    unmute
    unsubscribe
    versions
    your_dependent_repos
  ]

  def index
    if current_user
      muted_ids = params[:include_muted].present? ? [] : current_user.muted_project_ids
      @versions = current_user.all_subscribed_versions.where.not(project_id: muted_ids).where.not(published_at: nil).newest_first.includes(project: :versions).paginate(per_page: 20, page: page_number)
      render "dashboard/home"
    else
      @platforms = Project.maintained.group(:platform).order("count_id DESC").count("id").map { |k, v| { "key" => k, "doc_count" => v } }
    end
  end

  def deprecated
    project_scope(:deprecated)
  end

  def removed
    project_scope(:removed)
  end

  def unmaintained
    project_scope(:unmaintained)
  end

  def show
    if incorrect_case?
      if params[:number].present?
        return redirect_to(version_path(@project.to_param.merge(number: params[:number])), status: :moved_permanently)
      else
        return redirect_to(project_path(@project.to_param), status: :moved_permanently)
      end
    end
    find_version
    @contributors = @project.contributors.order("count DESC").visible.limit(24).select(:host_type, :name, :login, :uuid)
    @owners = @project.registry_users.limit(24)
  end

  def sourcerank; end

  def about
    find_version
    send_data render_to_string(:about, layout: false), filename: "#{@project.platform.downcase}-#{@project}.ABOUT", type: "application/text", disposition: "attachment"
  end

  def dependents
    # @dependents = @project.dependent_projects.visible.paginate(page: page_number)
  end

  def dependent_repos
    page_number = 0 if page_number.nil?
    @dependent_repos = @project.dependent_repositories_optimized(15, page_number).paginate(page: page_number + 1, per_page: 15)
  end

  def your_dependent_repos
    @dependent_repos = current_user.your_dependent_repos(@project).paginate(page: page_number)
  end

  def versions
    if incorrect_case?
      redirect_to(project_versions_path(@project.to_param), status: :moved_permanently)
    else
      @versions = @project.versions.order(published_at: :desc).paginate(page: page_number)
      respond_to do |format|
        format.html
        format.atom
      end
    end
  end

  def tags
    if incorrect_case?
      redirect_to(project_tags_path(@project.to_param), status: :moved_permanently)
    else
      @tags = if @project.repository.nil?
                []
              else
                @project.repository.tags.published.order("published_at DESC").paginate(page: page_number)
              end
      respond_to do |format|
        format.html
        format.atom
      end
    end
  end

  def mute
    current_user.mute(@project)
    flash[:notice] = "Muted #{@project} notifications"
    redirect_back fallback_location: project_path(@project.to_param)
  end

  def unmute
    current_user.unmute(@project)
    flash[:notice] = "Unmuted #{@project} notifications"
    redirect_back fallback_location: project_path(@project.to_param)
  end

  def unsubscribe; end

  def sync
    if @project.recently_synced?
      flash[:error] = "Project has already been synced recently"
    else
      # @see {Project#manual_sync}
      @project.manual_sync
      flash[:notice] = "Project has been queued to be resynced"
    end
    redirect_back fallback_location: project_path(@project.to_param)
  end

  def dependencies
    find_version
    render layout: false
  end

  def top_dependent_repos
    render layout: false
  end

  def top_dependent_projects
    render layout: false
  end

  def score
    @calculator = ProjectScoreCalculator.new(@project)
  end

  def refresh_stats
    @project.update_maintenance_stats_async
    flash[:notice] = "Project has been queued to refresh maintenance stats"
    redirect_back fallback_location: project_path(@project.to_param)
  end

  private

  def incorrect_case?
    params[:platform] != params[:platform].downcase || (@project && params[:name] != @project.name)
  end

  def current_platform
    PackageManager::Base.format_name(params[:platforms])
  end

  def project_scope(scope_name)
    @platforms = Project.visible.send(scope_name).group("platform").count.sort_by(&:last).reverse
    @projects = platform_scope.send(scope_name).includes(:repository).order("dependents_count DESC, projects.rank DESC NULLS LAST, projects.created_at DESC").paginate(page: page_number, per_page: 20)
  end
end
