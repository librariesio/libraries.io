# frozen_string_literal: true
class TreeController < ApplicationController
  before_action :find_project
  before_action :load_tree_resolver

  def show
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
