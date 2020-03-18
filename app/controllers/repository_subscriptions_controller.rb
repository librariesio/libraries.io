# frozen_string_literal: true

class RepositorySubscriptionsController < ApplicationController
  before_action :ensure_logged_in

  def edit
    @repository_subscription = current_user.repository_subscriptions.find(params[:id])
    @repository = @repository_subscription.repository
  end

  def update
    @repository_subscription = current_user.repository_subscriptions.find(params[:id])
    @repository_subscription.update_attributes(repository_subscription_params)
    redirect_to repositories_path
  end

  private

  def repository_subscription_params
    params.require(:repository_subscription).permit(:include_prerelease)
  end
end
