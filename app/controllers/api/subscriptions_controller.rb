class Api::SubscriptionsController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project, except: :index
  before_action :find_subscription, except: [:index, :create]

  def index
    @subscriptions = current_user.subscriptions.includes(:project)
    paginate json: @subscriptions, include: 'project,project.versions'
  end

  def show
    render json: @subscription, include: 'project,project.versions'
  end

  def create
    @subscription = current_user.subscriptions.create(subscription_params.merge(project_id: @project))
    render json: @subscription, include: 'project,project.versions'
  end

  def update
    @subscription.update_attributes(subscription_params)
    render json: @subscription, include: 'project,project.versions'
  end

  def destroy
    @subscription.destroy!
    head :no_content
  end

  private

  def subscription_params
    params.require(:subscription).permit(:include_prerelease)
  end

  def find_subscription
    @subscription = current_user.subscriptions.includes(:project).find_by_project_id(@project.id)
  end
end
