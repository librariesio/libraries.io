class TreeController < ApplicationController
  before_action :find_project

  def show
    @date = Date.parse(params[:date]) rescue Date.today

    if params[:number].present?
      @version = @project.versions.find_by_number(params[:number])
    else
      @version = @project.versions.where('versions.published_at < ?', @date).select(&:stable?).sort.first
    end
    raise ActiveRecord::RecordNotFound if @version.nil?

    @kind = params[:kind] || 'normal'

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
