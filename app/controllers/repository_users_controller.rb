class RepositoryUsersController < ApplicationController
  before_action :find_user

  def show
    @repositories = @user.repositories.open_source.source.order('status ASC NULLS FIRST, rank DESC NULLS LAST').limit(6)
    @favourite_projects = @user.top_favourite_projects.limit(6)
    @projects = @user.projects.visible.joins(:repository).includes(:versions).order('projects.rank DESC NULLS LAST, projects.created_at DESC').limit(6)
    if @user.org?
      @contributions = []
    else
      @contributions = find_contributions.limit(6)
    end
  end

  def dependencies
    orginal_scope = @user.favourite_projects.visible
    scope = params[:platforms].present? ? orginal_scope.platform(params[:platforms]) : orginal_scope
    @projects = scope.paginate(page: page_number)
    @platforms = orginal_scope.pluck(:platform).inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|_k,v| v }.reverse.first(20)
  end

  def repositories
    @repositories = @user.repositories.open_source.source.order('status ASC NULLS FIRST, rank DESC NULLS LAST').paginate(page: page_number)
  end

  def contributions
    @contributions = find_contributions.paginate(page: page_number)
  end

  def projects
    order = params[:sort] == "contributions" ? "repositories.contributions_count ASC, projects.rank DESC NULLS LAST, projects.created_at DESC" : 'projects.rank DESC NULLS LAST, projects.created_at DESC'
    @projects = @user.projects.visible.joins(:repository).includes(:repository).order(order).paginate(page: page_number)
  end

  def contributors
    @contributors = @user.contributors.select(:host_type, :name, :login, :uuid).paginate(page: params[:page])
  end

  def sync
    if @user.recently_synced?
      flash[:error] = "User has already been synced recently"
    else
      @user.manual_sync
      flash[:notice] = "User has been queued to be resynced"
    end
    redirect_back fallback_location: user_path(@user.to_param)
  end

  private

  def find_user
    @user = RepositoryUser.host(current_host).visible.login(params[:login]).first
    @user = RepositoryOrganisation.host(current_host).visible.login(params[:login]).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    redirect_to url_for(login: @user.login), :status => :moved_permanently if params[:login] != @user.login
  end

  def find_contributions
    @user.contributions.with_repo
                       .joins(:repository)
                       .where('repositories.repository_user_id != ?', @user.id)
                       .where('repositories.fork = ?', false)
                       .where('repositories.private = ?', false)
                       .includes(:repository)
                       .order('count DESC')
  end
end
