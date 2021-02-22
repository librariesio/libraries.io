# frozen_string_literal: true
class RepositoryTreeController < ApplicationController
  before_action :load_repo

  def show
    @date = Date.parse(params[:date]) rescue Date.today

    @tree_resolver = RepositoryTreeResolver.new(@repository, @date)

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
