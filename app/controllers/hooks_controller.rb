class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    if params[:payload]
      payload = JSON.parse(params[:payload])
    else
      payload = params
    end

    handler.run(request.env['HTTP_X_GITHUB_EVENT'], payload)

    render json: nil, status: :ok
  end

  def package
    PackageManagerDownloadWorker.perform_async(params['platform'], params['name'])

    render json: nil, status: :ok
  end

  private

  def handler
    @handler ||= GithubHookHandler.new
  end
end
