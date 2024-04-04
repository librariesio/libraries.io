# frozen_string_literal: true

class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_api_key
  before_action :add_rate_limit_headers

  RACK_ATTACK_THROTTLE_KEY = "rack.attack.throttle_data"

  private

  def add_rate_limit_headers
    throttle_data = request.env[RACK_ATTACK_THROTTLE_KEY]
      &.values
      &.min_by { |t| t[:limit] - t[:count] }
    return unless throttle_data

    now = throttle_data[:epoch_time]

    headers["X-RateLimit-Limit"]     = throttle_data[:limit].to_s
    headers["X-RateLimit-Remaining"] = (throttle_data[:limit] - throttle_data[:count]).to_s
    # "A response that includes the RateLimit-Limit header field MUST also include the RateLimit-Reset."
    # (from the IETF draft https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-07.html#section-4)
    headers["X-RateLimit-Reset"]     = (throttle_data[:period] - (now % throttle_data[:period])).to_s
  end

  def disabled_in_read_only
    render json: { error: "Error 503, Can't perform this action, the site is in read-only mode temporarily." }, status: :service_unavailable if in_read_only_mode?
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

  def internal_api_key?
    !!current_api_key&.is_internal?
  end

  def record_api_usage
    return unless @current_api_key.present?

    REDIS.hincrby "api-usage-#{Date.today.strftime('%Y-%m')}", @current_api_key.id, 1
  end

  def current_user
    current_api_key.try(:user)
  end

  def es_query(klass, query, filters)
    klass.search(query, filters: filters,
                        sort: format_sort,
                        order: format_order, api: true).paginate(page: page_number, per_page: per_page_number)
  end

  def require_internal_api_key
    render json: { error: "Error 403, you don't have permissions for this operation." }, status: :forbidden unless current_api_key.present? && current_api_key.is_internal?
  end
end
