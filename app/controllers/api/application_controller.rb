class Api::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_api_key

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { message: e.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { message: e.message }, status: :unprocessable_entity
  end

  private

  def max_page
    1000
  end

  def record_not_found(error)
    render json: { error: "404 Not Found" }, status: :not_found
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
    return nil if params[:api_key].blank?
    @current_api_key ||= ApiKey.active.find_by_access_token(params[:api_key])
  end

  def current_user
    current_api_key.try(:user)
  end

  def error_message
    { error: "Error 403, you don't have permissions for this operation." }
  end

  def es_query(klass, query, filters)
    klass.search(query, filters: filters,
                        sort: format_sort,
                        order: format_order, api: true).paginate(page: page_number, per_page: per_page_number)
  end
end
