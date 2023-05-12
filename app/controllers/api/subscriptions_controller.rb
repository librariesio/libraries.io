# frozen_string_literal: true

class Api::SubscriptionsController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project, except: :index
  before_action :find_subscription, except: %i[index create]
  before_action :disabled_in_read_only, only: %i[create update destroy]

  def index
    @subscriptions = current_user.subscriptions.includes(:project)
    paginate json: @subscriptions, include: "project,project.versions"
  end

  def show
    render json: @subscription, include: "project,project.versions"
  end

  def create
    @subscription = current_user.subscriptions.create(subscription_params.merge(project_id: @project.id))
    render json: @subscription, include: "project,project.versions"
  end

  def update
    @subscription.update(subscription_params)
    render json: @subscription, include: "project,project.versions"
  end

  def destroy
    @subscription.destroy!
    head :no_content
  end

  private

  def subscription_params
    params.permit(:subscription).permit(:include_prerelease)
  end

  def find_subscription
    @subscription = current_user.subscriptions.includes(:project).find_by_project_id(@project.id)
  end
end
