# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :ensure_logged_in, except: :home

  def index
    @orgs = current_user.adminable_repository_organisations.order(:login)
    @org = @orgs.find { |org| org.login == params[:org] }
    @repos = current_user.adminable_repositories.order("fork ASC, pushed_at DESC").paginate(per_page: 30, page: page_number)
    @repos = if @org
               @repos.from_org(@org)
             else
               @repos.from_org(nil)
             end
  end

  def home
    respond_to do |format|
      format.atom do
        if params[:api_key].present? && api_key = ApiKey.active.find_by_access_token(params[:api_key])
          @user = api_key.user
          @versions = @user.all_subscribed_versions.where.not(project_id: @user.muted_project_ids).where.not(published_at: nil).newest_first.includes(project: :versions).limit(50)
        else
          raise ActiveRecord::RecordNotFound
        end
      end
      format.html do
        redirect_to root_path
      end
    end
  end

  def muted
    @projects = current_user.muted_projects.visible.paginate(page: page_number)
  end

  def sync
    current_user.update_column(:currently_syncing, true)
    current_user.update_repo_permissions_async
    redirect_back fallback_location: repositories_path
  end

  def watch
    repository = Repository.find(params[:repository_id])
    current_user.subscribe_to_repo(repository)
    redirect_back fallback_location: repositories_path
  end

  def unwatch
    repository = Repository.find(params[:repository_id])
    current_user.unsubscribe_from_repo(repository)
    redirect_back fallback_location: repositories_path
  end

  private

  def repository_subscription_params
    params.require(:repository_subscription).permit(:include_prerelease)
  end
end
