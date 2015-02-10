class PlatformsController < ApplicationController
  def index
    @platforms = Project.search('*').response.facets[:platforms][:terms].sort_by(&:term)
  end

  def show
    find_platform
    scope = Project.platform(@platform_name)
    @licenses = scope.popular_licenses_sql.limit(8).to_a
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @contributors = GithubUser.top_for(@platform_name, 24)
    @popular = scope.with_repo.limit(50)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
  end
end
