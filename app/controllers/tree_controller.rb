class TreeController < ApplicationController
  before_action :find_project

  def show
    find_version
    @project_names = [@project.name]
    @license_names = @project.normalize_licenses
  end

  private

  def find_version
    @version_count = @project.versions.size
    if @version_count.zero?
      @versions = []
      @github_repository = @project.github_repository
      if @github_repository.present?
        @github_tags = @github_repository.github_tags.published.order('published_at DESC').limit(10).to_a.sort
        if params[:version].present?
          @version = @github_repository.github_tags.published.find_by_name(params[:version])
          raise ActiveRecord::RecordNotFound if @version.nil?
        end
      else
        @github_tags = []
      end
      if @github_tags.empty?
        raise ActiveRecord::RecordNotFound if params[:version].present?
      end
    else
      @versions = @project.versions.sort.first(10)
      if params[:version].present?
        @version = @project.versions.find_by_number(params[:version])
        raise ActiveRecord::RecordNotFound if @version.nil?
      end
    end
    if @version.nil?
      @version = @project.latest_release
      raise ActiveRecord::RecordNotFound if @version.nil?
    end
  end
end
