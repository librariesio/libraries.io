class PlatformsController < ApplicationController
  def index
    @platforms = Download.platforms
  end

  def show
    @platform = Download.platforms.find{|p| p.to_s.demodulize.downcase == params[:id].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
    @licenses = Project.platform(@platform_name).popular_licenses.limit(8).to_a
    @updated = Project.platform(@platform_name).limit(5).order('updated_at DESC')
    @created = Project.platform(@platform_name).limit(5).order('created_at DESC')
    @popular = Project.platform(@platform_name).with_repo.limit(5).order('github_repositories.stargazers_count DESC')
    @contributors = GithubUser.top_for(@platform_name, 5)
  end
end
