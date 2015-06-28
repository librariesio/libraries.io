class Api::GithubRepositoriesController < Api::ApplicationController
  #before_action :check_api_key

  def show
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @github_repository.nil?

    render json: @github_repository.as_json({
      include: {
        repository_dependencies: {only: [:platform, :project_name, :requirements]}
      }
    })
  end
end
