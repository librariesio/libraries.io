class ManifestsController < ApplicationController
  before_action :ensure_logged_in

  def index
    @repos = current_user.github_client.repos(nil, accept: 'application/vnd.github.moondragon+json')
    @manifests = current_user.manifests
  end

  def show
    @manifest = current_user.manifests.find(params[:id])
    @repository = @manifest.repository
    @subscriptions = @manifest.subscriptions
  end

  def create
    @manifest = current_user.manifests.find_or_create_by(repository_id: params[:repository_id])
    parse(@manifest)
    redirect_to @manifest
  end

  def update
    @manifest = current_user.manifests.find(params[:id])
    parse(@manifest)
    redirect_to @manifest
  end

  def destroy
    # remove webhook
    # delete manifest and subscriptions
  end

  private

  def parse(manifest)
    # on librarian:
    #   look for known manifest files
    #   parse manifest files
    #   add webhook on push and pr
    #   create subscriptions
  end
end
