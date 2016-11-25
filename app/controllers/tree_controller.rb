class TreeController < ApplicationController
  before_action :find_project

  def show
    find_version
    if @version.nil?
      @version = @project.latest_stable_version
      raise ActiveRecord::RecordNotFound if @version.nil?
    end
    @kind = params[:kind] || 'normal'
    @date = Date.parse(params[:date]) rescue nil
    @tree_resolver = TreeResolver.new(@version, @kind, @date)

    if @tree_resolver.cached?
      @tree = @tree_resolver.tree
      @project_names = @tree_resolver.project_names
      @license_names = @tree_resolver.license_names
    end

    if request.xhr?
      render :_tree, layout: false, tree: @tree
    else
      if !@tree_resolver.cached?
        @tree_resolver.enqueue_tree_resolution
      end
    end
  end
end
