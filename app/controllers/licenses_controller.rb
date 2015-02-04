class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses(21)
  end

  def show
    @license = params[:id]
    scope = Project.license(@license)
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = scope.with_repo.limit(5).order('github_repositories.stargazers_count DESC')
  end
end
