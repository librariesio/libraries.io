# frozen_string_literal: true

class Api::ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.repository_dependencies.where("repositories.fork = ?", false).joins(manifest: :repository).distinct("manifests.repository_id").group("repository_dependencies.requirements").count.select { |k, _v| k.present? }

    render json: @all_counts
  end
end
