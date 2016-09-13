class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_api_key, :set_headers

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def max_page
    1000
  end

  def record_not_found(error)
    render json: { error: "404 Not Found" }, status: :not_found
  end

  def set_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match'
    headers['Access-Control-Max-Age'] = '86400'
  end

  def check_api_key
    return true if params[:api_key].nil?
    render :json => error_message, :status => :bad_request unless valid_api_key_present?
  end

  def require_api_key
    render :json => error_message, :status => :bad_request unless valid_api_key_present?
  end

  def valid_api_key_present?
    params[:api_key].present? && current_api_key
  end

  def current_api_key
    ApiKey.active.find_by_access_token(params[:api_key])
  end

  def current_user
    current_api_key.try(:user)
  end

  def error_message
    { error: "Error 403, you don't have permissions for this operation." }
  end
end
