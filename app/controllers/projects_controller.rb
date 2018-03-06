class ProjectsController < ApplicationController
  before_action :ensure_logged_in, only: [:your_dependent_repos, :mute, :unmute,
                                          :unsubscribe, :sync]
  before_action :find_project, only: [:show, :sourcerank, :about, :dependents,
                                      :dependent_repos, :your_dependent_repos,
                                      :versions, :tags, :mute, :unmute, :unsubscribe,
                                      :sync]
  before_action :find_project_lite, only: [:top_dependent_repos, :top_dependent_projects]

  def index
    if current_user
      muted_ids = params[:include_muted].present? ? [] : current_user.muted_project_ids
      @versions = current_user.all_subscribed_versions.where.not(project_id: muted_ids).where.not(published_at: nil).newest_first.includes(project: :versions).paginate(per_page: 20, page: page_number)
      render 'dashboard/home'
    else
      facets = Project.facets(:facet_limit => 40)

      @platforms = facets[:platforms].platform.buckets
    end
  end

  def bus_factor
    problem_repos(:bus_factor_search)
  end

  def unlicensed
    problem_repos(:unlicensed_search)
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
        return redirect_to(version_path(@project.to_param.merge(number: params[:number])), :status => :moved_permanently)
      else
        return redirect_to(project_path(@project.to_param), :status => :moved_permanently)
      end
    end
    find_version
    @contributors = @project.contributors.order('count DESC').visible.limit(24).select(:host_type, :name, :login, :uuid)
    @owners = @project.registry_users.limit(24)
  end

  def sourcerank

  end

  def about
    find_version
    send_data render_to_string(:about, layout: false), filename: "#{@project.platform.downcase}-#{@project}.ABOUT", type: 'application/text', disposition: 'attachment'
  end

  def dependents
    @dependents = @project.dependent_projects.visible.paginate(page: page_number)
  end

  def dependent_repos
    @dependent_repos = @project.dependent_repositories.open_source.paginate(page: page_number)
  end

  def your_dependent_repos
    @dependent_repos = current_user.your_dependent_repos(@project).paginate(page: page_number)
  end

  def versions
    if incorrect_case?
      return redirect_to(project_versions_path(@project.to_param), :status => :moved_permanently)
    else
      @versions = @project.versions.sort.paginate(page: page_number)
      respond_to do |format|
        format.html
        format.atom
      end
    end
  end

  def tags
    if incorrect_case?
      return redirect_to(project_tags_path(@project.to_param), :status => :moved_permanently)
    else
      if @project.repository.nil?
        @tags = []
      else
        @tags = @project.repository.tags.published.order('published_at DESC').paginate(page: page_number)
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

  def trending
    orginal_scope = Project.includes(:repository).recently_created.maintained
    scope = current_platform.present? ? orginal_scope.platform(current_platform) : orginal_scope
    scope = current_language.present? ? scope.language(current_language) : scope
    @projects = scope.hacker_news.paginate(page: page_number, per_page: 20)
    @platforms = orginal_scope.where('repositories.stargazers_count > 0').group('projects.platform').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(20)
  end

  def unsubscribe

  end

  def sync
    if @project.recently_synced?
      flash[:error] = "Project has already been synced recently"
    else
      @project.manual_sync
      flash[:notice] = "Project has been queued to be resynced"
    end
    redirect_back fallback_location: project_path(@project.to_param)
  end

  def digital_infrastructure
    orginal_scope = Project.digital_infrastructure
    scope = current_platform.present? ? orginal_scope.platform(current_platform) : orginal_scope
    @projects = scope.order('projects.dependent_repos_count DESC').paginate(page: page_number)
    @platforms = orginal_scope.group('projects.platform').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(20)
  end

  def unseen_infrastructure
    orginal_scope = Project.unsung_heroes
    scope = current_platform.present? ? orginal_scope.platform(current_platform) : orginal_scope
    @projects = scope.order('projects.dependent_repos_count DESC').paginate(page: page_number)
    @platforms = orginal_scope.group('projects.platform').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(20)
  end

  def dependencies
    find_project_lite
    find_version
    render layout: false
  end

  def top_dependent_repos
    render layout: false
  end

  def top_dependent_projects
    render layout: false
  end

  private

  def problem_repos(method_name)
    @search = Project.send(method_name, filters: {
      platform: current_platform,
      normalized_licenses: current_license,
      language: current_language
    }).paginate(page: page_number)
    @projects = @search.records.includes(:repository)
    @facets = @search.response.aggregations
  end

  def incorrect_case?
    params[:platform] != params[:platform].downcase || (@project && params[:name] != @project.name)
  end

  def current_platform
    PackageManager::Base.format_name(params[:platforms])
  end

  def project_scope(scope_name)
    @platforms = Project.visible.send(scope_name).group('platform').count.sort_by(&:last).reverse
    @projects = platform_scope.send(scope_name).includes(:repository).order('dependents_count DESC, projects.rank DESC NULLS LAST, projects.created_at DESC').paginate(page: page_number, per_page: 20)
  end
end
