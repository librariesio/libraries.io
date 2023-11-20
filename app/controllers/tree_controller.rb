# frozen_string_literal: true

class TreeController < ApplicationController
  before_action :find_project
  before_action :load_tree_resolver

  def show
    # if cache is disabled (such as in dev), just do this synchronously
    if cache_disabled? || @tree_resolver.cached?
      @tree = @tree_resolver.tree
      @project_names = @tree_resolver.project_names
      @license_names = @tree_resolver.license_names
    end

    if request.xhr?
      render :_tree, layout: false, tree: @tree
    elsif !@tree_resolver.cached?
      @tree_resolver.enqueue_tree_resolution
    end
  end

  private

  def cache_disabled?
    Rails.application.config.cache_store == :null_store
  end
end
