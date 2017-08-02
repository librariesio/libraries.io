module Experiments
  class SimilarNamesController < ApplicationController
    def index
      @projects = Project.joins(:similar_names).order('created_at DESC').paginate(page: params[:page])
    end
  end
end
