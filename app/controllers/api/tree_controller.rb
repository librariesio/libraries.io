class Api::TreeController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project

  def show
    find_version
    if @version.nil?
      @version = @project.latest_stable_version
      raise ActiveRecord::RecordNotFound if @version.nil?
    end
    @kind = params[:kind] || 'normal'
    render json: TreeResolver.new(@version, @kind).tree
  end
end
