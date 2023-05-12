# frozen_string_literal: true

class Admin::RepositoryOrganisationsController < Admin::ApplicationController
  before_action :find_user

  def show
    @top_repos = @user.repositories.open_source.source.order("contributions_count DESC NULLS LAST, rank DESC NULLS LAST").limit(10)
    @total_commits = @user.repositories.map { |r| r.contributions.sum(:count) }.sum
    @counts = @user.favourite_projects.count
  end

  def dependencies
    @counts = @user.favourite_projects.count

    orginal_scope = @user.favourite_projects.visible
    scope = params[:platforms].present? ? orginal_scope.platform(params[:platforms]) : orginal_scope
    @projects = scope.paginate(page: params[:page], per_page: per_page_number)
    @platforms = orginal_scope.pluck(:platform).each_with_object(Hash.new(0)) do |v, h|
                   h[v] += 1
                 end.sort_by { |_k, v| v }.reverse.first(20)
  end

  def edit; end

  def update
    @user.update(user_params)
    redirect_to admin_edit_owner_path(@user.host_type.downcase, @user.login), notice: "#{@user.org? ? 'Organisation' : 'User'} updated"
  end

  def destroy
    @user.repositories.each(&:destroy)
    @user.destroy
    redirect_to admin_stats_path, notice: "#{@user.org? ? 'Organisation' : 'User'} and their repositories deleted"
  end

  def hide
    @user.repositories.each(&:hide)
    @user.hide
    redirect_to admin_stats_path, notice: "#{@user.org? ? 'Organisation' : 'User'} and their repositories hidden"
  end

  private

  def find_user
    @user = RepositoryUser.host(current_host).login(params[:login]).first
    @user = RepositoryOrganisation.host(current_host).login(params[:login]).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?

    redirect_to url_for(login: @user.login), status: :moved_permanently if params[:login] != @user.login
  end

  def user_params
    if @user.org?
      params.require(:repository_organisation).permit(:hidden)
    else
      params.require(:repository_user).permit(:hidden)
    end
  end
end
