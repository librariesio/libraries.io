class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    GithubHookWorker.perform_async(params["repository"]["id"], params["sender"]["id"])

    render json: nil, status: :ok
  end
end
