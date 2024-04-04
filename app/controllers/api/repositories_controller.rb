# frozen_string_literal: true

class Api::RepositoriesController < Api::ApplicationController
  before_action :find_repo, except: :search

  def show
    repo_json = RepositorySerializer.new(@repository).as_json
    repo_json[:maintenance_stats] = maintenance_stats(@repository) if internal_api_key?
    render json: repo_json
  end

  def projects
    paginate json: @repository.projects.visible.order(custom_order).includes(:versions, :repository)
  end

  def dependencies
    cache_key = "repository_dependencies:#{@repository.id}"
    json_hash = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      result = RepositorySerializer.new(@repository).as_json
      result[:dependencies] = map_dependencies(@repository.repository_dependencies.includes(:project, :manifest) || []).map(&:as_json)
      result
    end
    render json: json_hash
  end

  # Terse payload with only the information that shields.io needs.
  def shields_dependencies
    cache_key = "shields_dependencies:#{@repository.id}"
    json_hash = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      # The distinct cuts down the query since repositories that have many manifests tend to have many dupes.
      deps = RepositoryDependency
        .strict_loading
        .where(repository: @repository)
        .select("DISTINCT ON (project_id, requirements) *")
        .includes(:project)

      deprecated_count = deps
        .select(&:deprecated?)
        .size

      outdated_count = deps
        .select(&:outdated?)
        .size
      { deprecated_count: deprecated_count, outdated_count: outdated_count }
    end

    render json: json_hash
  end

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join("/")
    @repository = Repository.host(current_host).open_source.where("lower(full_name) = ?", full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @repository.nil?
  end

  def allowed_sorts
    %w[rank stargazers_count contributions_count created_at pushed_at subscribers_count open_issues_count forks_count size]
  end

  def maintenance_stats(repository)
    Datadog::Tracing.trace("repositories_controller#maintenance_stats") do |_span, _trace|
      RepositoryMaintenanceStat
        .where(repository: repository)
        .pluck(*RepositoryMaintenanceStat::API_FIELDS, :repository_id)
        .map { |stat| RepositoryMaintenanceStat::API_FIELDS.zip(stat).to_h }
    end
  end
end
