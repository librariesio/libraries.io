class PlatformsController < ApplicationController
  def index
    @platforms = Download.platforms
  end

  def show
    @platform = "Repositories::#{params[:id]}".constantize
    @platform_name = @platform.to_s.demodulize
    @licenses = Project.platform(@platform_name).popular_licenses.to_a
    @updated = Project.platform(@platform_name).limit(5).order('updated_at DESC')
    @popular = Project.platform(@platform_name).with_repo.limit(5).order('github_repositories.stargazers_count DESC')
    @contributors = GithubUser.top_for(@platform_name, 6)
  end
end
