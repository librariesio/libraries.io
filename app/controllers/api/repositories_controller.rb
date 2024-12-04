# frozen_string_literal: true

class Api::RepositoriesController < Api::ApplicationController
  before_action :find_repo, except: :search
  before_action :require_internal_api_key, only: :sync

  def show
    include_readme = ActiveModel::Type::Boolean.new.cast(params[:include_readme])
    repo_json = RepositorySerializer.new(@repository, include_readme: include_readme).as_json
    repo_json[:maintenance_stats] = maintenance_stats(@repository) if internal_api_key?
    render json: repo_json
  end

  def projects
    paginate json: @repository.projects.visible.order(custom_order).includes(:versions, :repository)
  end

  def project_names
    columns = %i[platform name]
    render json: Project.visible.select(columns).where(repository: @repository).order(custom_order).as_json(only: columns)
  end

  def dependencies
    cache_key = "repository_dependencies:#{@repository.id}"
    json_hash = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      result = RepositorySerializer.new(@repository).as_json
      result[:dependencies] = map_dependencies(@repository.projects_dependencies).map(&:as_json)
      result
    end
    render json: json_hash
  end

  # Terse payload with only the information that shields.io needs.
  def shields_dependencies
    cache_key = "shields_dependencies:#{@repository.id}"
    json_hash = Rails.cache.fetch(cache_key, expires_in: 1.day) do
      deps = @repository
        .projects_dependencies.includes(:project)

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

  def sync
    if @repository.recently_synced?
      StructuredLog.capture(
        "REPOSITORY_MANUAL_SYNC_REQUEST_SKIPPED", {
          host_type: @repository.host_type,
          full_name: @repository.full_name,
          last_synced_at: @repository.last_synced_at,
        }
      )
      render json: { error: "Repository has already been synced recently" }
    else
      @repository.manual_sync
      render json: { message: "Repository queued for re-sync" }
    end
  end

  private

  # handle a missing owner or name parameter when doing the lookup for Repository in find_repo
  # and return a formatted JSON with the missing parameter name with a 400 HTTP status code
  rescue_from ActionController::ParameterMissing do |e|
    errors = { e.param => ["is required"] }
    render json: errors, status: :bad_request
  end

  def find_repo
    full_name = params.require(%i[owner name]).join("/")
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
