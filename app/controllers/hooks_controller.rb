# frozen_string_literal: true
class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    if params[:payload]
      payload = JSON.parse(params[:payload])
    else
      payload = params
    end

    @github_event = request.env['HTTP_X_GITHUB_EVENT']    
    handler.run(@github_event, payload)

    render json: nil, status: :ok
  end

  def package
    if params['platform'].blank?
      Rails.logger.info "HooksController#package invalid=true platform=#{params['platform']} name=#{params['name']} param_keys=#{params.keys.join(',')}"
    else
      Rails.logger.info "HooksController#package platform=#{params['platform']} name=#{params['name']} param_keys=#{params.keys.join(',')}"
      PackageManagerDownloadWorker.perform_async("PackageManager::#{params['platform']}", params["name"], nil, "hooks")
    end

    render json: nil, status: :ok
  end

  private

  def handler
    @handler ||= GithubHookHandler.new
  end
end
