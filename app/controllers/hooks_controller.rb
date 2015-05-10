class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def github
    github_repository = GithubRepository.find_by_github_id(params["repository"]["id"])
    user = User.find_by_uid(params["sender"]["id"])
    github_repository.download_manifests(user.token)

    render json: nil, status: :ok
  end
end
