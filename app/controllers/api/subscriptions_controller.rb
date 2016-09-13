class Api::SubscriptionsController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project, except: :index
  before_action :find_subscription, except: [:index, :create]

  def index
    @subscriptions = current_user.subscriptions.includes(:project)
    paginate json: @subscriptions.as_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} }}})
  end

  def show
    render json: @subscription.as_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} }}})
  end

  def create
    @subscription = current_user.subscriptions.create(subscription_params.merge(project_id: @project))
    render json: @subscription.as_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} }}})
  end

  def update
    @subscription.update_attributes(subscription_params)
    render json: @subscription.as_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} }}})
  end

  def destroy
    @subscription.destroy!
    render status: 204
  end

  private

  def subscription_params
    params.require(:subscription).permit(:include_prerelease)
  end

  def find_subscription
    @subscription = current_user.subscriptions.includes(:project).find_by_project_id(@project.id)
  end

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).first
    raise ActiveRecord::RecordNotFound if @project.nil?
  end
end
