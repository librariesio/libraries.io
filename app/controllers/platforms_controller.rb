class PlatformsController < ApplicationController
  def index
    @platforms = Download.platforms
  end

  def show
    find_platform
    @licenses = Project.platform(@platform_name).popular_licenses.limit(8).to_a
    @updated = Project.platform(@platform_name).limit(5).order('updated_at DESC')
    @created = Project.platform(@platform_name).limit(5).order('created_at DESC')
    @contributors = GithubUser.top_for(@platform_name, 24)
    @popular = Project.platform(@platform_name).with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
  end
end
