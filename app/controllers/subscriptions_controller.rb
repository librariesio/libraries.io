class SubscriptionsController < ApplicationController
  before_action :ensure_logged_in

  def index
    @subscriptions = current_user.subscriptions.includes(project: :versions).order('projects.latest_release_published_at DESC').paginate(page: params[:page])
    @projects = current_user.recommended_projects.limit(5)
  end

  def update
    @subscription = current_user.subscriptions.find(params[:id])
    @subscription.update_attributes(subscription_params)
    redirect_to_back_or_default project_path(@subscription.project.to_param)
  end

  def subscribe
    @subscription = current_user.subscriptions.create(project_id: params[:project_id])
    redirect_to_back_or_default project_path(@subscription.project.to_param)
  end

  def destroy
    @subscription = current_user.subscriptions.find(params[:id])
    @subscription.destroy!
    redirect_to_back_or_default project_path(@subscription.project.to_param)
  end

  private

  def subscription_params
    params.require(:subscription).permit(:include_prerelease)
  end
end
