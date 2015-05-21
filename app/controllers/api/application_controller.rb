class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token

  protected

  def check_api_key
    render :json => error_message, :status => :bad_request unless api_key_present?
  end

  def api_key_present?
    params[:api_key].present? && ApiKey.active.find_by_access_token(params[:api_key])
  end

  def error_message
    { error: "Error 403, you don't have permissions for this operation." }
  end
end
