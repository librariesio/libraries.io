class TreeController < ApplicationController
  before_action :find_project

  def show
    find_version
    if @version.nil?
      @version = @project.latest_stable_version
      raise ActiveRecord::RecordNotFound if @version.nil?
    end
    @kind = params[:kind] || 'normal'
    tree_resolver = TreeResolver.new(@version, @kind)
    @tree = tree_resolver.generate_dependency_tree
    @project_names = tree_resolver.project_names
    @license_names = tree_resolver.license_names
  end
end
