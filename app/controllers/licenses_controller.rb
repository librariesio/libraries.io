class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses
  end

  def show
    find_license
    scope = Project.license(@license.id)
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = scope.with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
  end

  private

  def find_license
    @license = Spdx.find(params[:id])
    raise ActiveRecord::RecordNotFound if @license.nil?
    redirect_to license_path(@license.id), :status => :moved_permanently if @license.id != params[:id]
  end
end
