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
    repo_json = RepositorySerializer.new(@repository).as_json
    repo_json[:dependencies] = map_dependencies(@repository.repository_dependencies.includes(:project, :manifest) || [])

    render json: repo_json
  end

  def search
    @search = paginate(search_repos(params[:q]))
    @repositories = @search.records

    render json: @repositories
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
