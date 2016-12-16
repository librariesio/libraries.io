class ProjectsController < ApplicationController
  before_action :ensure_logged_in, only: [:your_dependent_repos, :mute, :unmute]
  etag { current_user.try :id }

  def index
    if current_user
      muted_ids = params[:include_muted].present? ? [] : current_user.muted_project_ids
      @versions = current_user.all_subscribed_versions.where.not(project_id: muted_ids).where.not(published_at: nil).newest_first.includes(project: :versions).paginate(per_page: 20, page: page_number)
      @projects = current_user.recommended_projects.limit(7)
      render 'dashboard/home'
    else
      facets = Project.facets(:facet_limit => 30)

      @languages = facets[:languages][:terms]
      @platforms = facets[:platforms][:terms]
      @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
      @keywords = facets[:keywords][:terms]
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
    find_project
    if incorrect_case?
      if params[:number].present?
        return redirect_to(version_path(@project.to_param.merge(number: params[:number])), :status => :moved_permanently)
      else
        return redirect_to(project_path(@project.to_param), :status => :moved_permanently)
      end
    end
    find_version
    fresh_when([@project, @version])
    @dependencies = (@versions.size > 0 ? (@version || @versions.first).dependencies.includes(project: :versions).order('project_name ASC').limit(100) : [])
    @contributors = @project.contributors.order('count DESC').visible.limit(20)
  end

  def sourcerank
    find_project
  end

  def about
    find_project
    find_version
    send_data render_to_string(:about, layout: false), filename: "#{@project.platform.downcase}-#{@project}.ABOUT", type: 'application/text', disposition: 'attachment'
  end

  def dependents
    find_project
    @dependents = @project.dependent_projects.paginate(page: page_number)
  end

  def dependent_repos
    find_project
    @dependent_repos = @project.dependent_repositories.open_source.paginate(page: page_number)
  end

  def your_dependent_repos
    find_project
    @dependent_repos = current_user.your_dependent_repos(@project).paginate(page: page_number)
  end

  def versions
    find_project
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
    find_project
    if incorrect_case?
      return redirect_to(project_tags_path(@project.to_param), :status => :moved_permanently)
    else
      if @project.github_repository.nil?
        @tags = []
      else
        @tags = @project.github_tags.published.order('published_at DESC').paginate(page: page_number)
      end
      respond_to do |format|
        format.html
        format.atom
      end
    end
  end

  def mute
    find_project
    current_user.mute(@project)
    redirect_to_back_or_default project_path(@project.to_param)
  end

  def unmute
    find_project
    current_user.unmute(@project)
    redirect_to_back_or_default project_path(@project.to_param)
  end

  def trending
    orginal_scope = Project.includes(:github_repository).recently_created.maintained
    scope = current_platform.present? ? orginal_scope.platform(current_platform) : orginal_scope
    scope = current_language.present? ? scope.language(current_language) : scope
    @projects = scope.hacker_news.paginate(page: page_number)
    @platforms = orginal_scope.where('github_repositories.stargazers_count > 0').group('projects.platform').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(20)
  end

  private

  def problem_repos(method_name)
    @search = Project.send(method_name, filters: {
      platform: current_platform,
      normalized_licenses: current_license,
      language: current_language
    }).paginate(page: page_number)
    indexes = Hash[@search.map{|r| r.id.to_i }.each_with_index.to_a]
    @projects = @search.records.includes(:github_repository).sort_by { |u| indexes[u.id] }
  end

  def incorrect_case?
    params[:platform] != params[:platform].downcase || (@project && params[:name] != @project.name)
  end

  def current_platform
    Repositories::Base.format_name(params[:platforms])
  end

  def current_language
    Languages::Language[params[:language]].to_s if params[:language].present?
  end

  def current_license
    Spdx.find(params[:license]).try(:id) if params[:license].present?
  end

  def project_scope(scope_name)
    @platforms = Project.send(scope_name).group('platform').count.sort_by(&:last).reverse
    @projects = platform_scope.send(scope_name).includes(:github_repository).order('dependents_count DESC, projects.rank DESC, projects.created_at DESC').paginate(page: page_number, per_page: 20)
  end
end
