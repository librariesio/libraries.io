class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    if params[:payload]
      payload = JSON.parse(params[:payload])
      GithubHookWorker.perform_async(payload["repository"]["id"], payload["sender"]["id"])
    else
      GithubHookWorker.perform_async(params["repository"]["id"], params["sender"]["id"])
    end

    render json: nil, status: :ok
  end
end
