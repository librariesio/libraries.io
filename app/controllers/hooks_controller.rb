class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def github
    github_repository = GithubRepository.find_by_github_id(params["repository"]["id"])
    user = User.find_by_uid(params["sender"]["id"])
    if user.present? && github_repository.present?
      github_repository.download_manifests(user.token)
    end

    render json: nil, status: :ok
  end
end
