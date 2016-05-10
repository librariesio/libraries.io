class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :set_headers

  private

  def set_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match'
    headers['Access-Control-Max-Age'] = '86400'
  end

  def check_api_key
    render :json => error_message, :status => :bad_request unless api_key_present?
  end

  def api_key_present?
    return true if Rails.env.development?

    # FIXME temporary, shields.io is not sending a key at the moment
    return true if params[:api_key].nil?

    params[:api_key].present? && ApiKey.active.find_by_access_token(params[:api_key])
  end

  def error_message
    { error: "Error 403, you don't have permissions for this operation." }
  end
end
