# frozen_string_literal: true

class Api::TreeController < Api::ApplicationController
  before_action :require_api_key
  before_action :find_project
  before_action :load_tree_resolver

  def show
    render json: @tree_resolver.tree
  end
end
