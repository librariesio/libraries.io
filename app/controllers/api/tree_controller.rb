class Api::TreeController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project

  def show
    @date = Date.parse(params[:date]) rescue Date.today

    if params[:number].present?
      @version = @project.versions.find_by_number(params[:number])
    else
      @version = @project.versions.where('versions.published_at < ?', @date).select(&:stable?).sort.first
    end
    raise ActiveRecord::RecordNotFound if @version.nil?

    @kind = params[:kind] || 'normal'
    render json: TreeResolver.new(@version, @kind, @date).tree
  end
end
