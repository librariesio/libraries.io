class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_api_key

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { message: e.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { message: e.message }, status: :unprocessable_entity
  end

  private

  def disabled_in_read_only
    if in_read_only_mode?
      render json: { error: "Error 503, Can't perform this action, the site is in read-only mode temporarily." }, status: :service_unavailable
    end
  end

  def max_page
    300
  end

  def check_api_key
    return true if params[:api_key].nil?
    require_api_key
    record_api_usage
  end

  def require_api_key
    render json: { error: "Error 403, you don't have permissions for this operation." }, status: :forbidden unless valid_api_key_present?
  end

  def valid_api_key_present?
    params[:api_key].present? && current_api_key
  end

  def current_api_key
    return nil if params[:api_key].blank?
    @current_api_key ||= ApiKey.active.find_by_access_token(params[:api_key])
  end

  def record_api_usage
    return unless @current_api_key.present?
    REDIS.hincrby "api-usage-#{Date.today.strftime("%Y-%m")}", @current_api_key.id, 1
  end

  def current_user
    current_api_key.try(:user)
  end

  def es_query(klass, query, filters)
    klass.search(query, filters: filters,
                        sort: format_sort,
                        order: format_order, api: true).paginate(page: page_number, per_page: per_page_number)
  end
end
