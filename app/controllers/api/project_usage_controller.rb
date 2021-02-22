# frozen_string_literal: true
class Api::ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.repository_dependencies.joins(:repository).group('repository_dependencies.requirements').count.select{|k,v| k.present? }

    render json: @all_counts
  end
end
