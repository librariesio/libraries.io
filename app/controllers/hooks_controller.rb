# frozen_string_literal: true

class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    payload = if params[:payload]
                JSON.parse(params[:payload])
              else
                params
              end

    @github_event = request.env["HTTP_X_GITHUB_EVENT"]
    handler.run(@github_event, payload)

    render json: nil, status: :ok
  end

  private

  def handler
    @handler ||= GithubHookHandler.new
  end
end
