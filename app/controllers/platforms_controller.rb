class PlatformsController < ApplicationController
  before_action :find_platform, :only => [:show, :legacy]

  def index
    @platforms = Download.platforms
  end

  def show
    @licenses = Project.platform(@platform_name).popular_licenses.limit(8).to_a
    @updated = Project.platform(@platform_name).limit(5).order('updated_at DESC')
    @created = Project.platform(@platform_name).limit(5).order('created_at DESC')
    @contributors = GithubUser.top_for(@platform_name, 5)
    @popular = Project.platform(@platform_name).with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
  end

  def legacy
    redirect_to platform_path(@platform_name.downcase), :status => :moved_permanently
  end

  private

  def find_platform
    @platform = Download.platforms.find{|p| p.to_s.demodulize.downcase == params[:id].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
  end
end
