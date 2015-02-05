class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses.limit(42)
  end

  def show
    @license = params[:id]
    scope = Project.license(@license)
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = scope.with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
  end
end
