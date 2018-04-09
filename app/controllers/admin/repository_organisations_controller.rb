class Admin::RepositoryOrganisationsController < Admin::ApplicationController
  before_action :find_user

  def show
    @top_repos = @user.repositories.open_source.source.order('contributions_count DESC NULLS LAST, rank DESC NULLS LAST').limit(10)
    @total_commits = @user.repositories.map{|r| r.contributions.sum(:count) }.sum
    @counts = @user.favourite_projects.count
  end

  def dependencies
    @counts = @user.favourite_projects.count

    orginal_scope = @user.favourite_projects.visible
    scope = params[:platforms].present? ? orginal_scope.platform(params[:platforms]) : orginal_scope
    @projects = scope.paginate(page: params[:page], per_page: per_page_number)
    @platforms = orginal_scope.pluck(:platform).inject(Hash.new(0)) { |h,v| h[v] += 1; h }.sort_by{|_k,v| v }.reverse.first(20)
  end

  private

  def find_user
    @user = RepositoryUser.host(current_host).visible.login(params[:login]).first
    @user = RepositoryOrganisation.host(current_host).visible.login(params[:login]).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    redirect_to url_for(login: @user.login), :status => :moved_permanently if params[:login] != @user.login
  end
end
