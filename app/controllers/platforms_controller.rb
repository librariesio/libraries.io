class PlatformsController < ApplicationController
  def index
    @platforms = Download.platforms
  end

  def show
    @platform = "Repositories::#{params[:id]}".constantize
    @platform_name = @platform.to_s.demodulize
    @licenses = Project.platform(@platform_name).popular_licenses
    limit = 5
    @added = Project.platform(@platform_name).limit(limit).order('created_at DESC')
    @updated = Project.platform(@platform_name).limit(limit).order('updated_at DESC')
  end
end
