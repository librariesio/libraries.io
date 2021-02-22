# frozen_string_literal: true
class SubscriptionsController < ApplicationController
  before_action :ensure_logged_in

  def index
    @subscriptions = current_user.subscriptions.includes(project: :versions).order('projects.latest_release_published_at DESC').paginate(page: params[:page])
  end

  def update
    @subscription = current_user.subscriptions.find(params[:id])
    @subscription.update(subscription_params)
    flash[:notice] = "Updated #{@subscription.project} subscription options"
    redirect_back fallback_location: project_path(@subscription.project.to_param)
  end

  def subscribe
    @subscription = current_user.subscriptions.create(project_id: params[:project_id])
    flash[:notice] = "Subscribed from #{@subscription.project} notifications"
    redirect_back fallback_location: project_path(@subscription.project.to_param)
  end

  def destroy
    @subscription = current_user.subscriptions.find(params[:id])
    @subscription.destroy!
    flash[:notice] = "Unsubscribed from #{@subscription.project} notifications"
    redirect_back fallback_location: project_path(@subscription.project.to_param)
  end

  private

  def subscription_params
    params.require(:subscription).permit(:include_prerelease)
  end
end
