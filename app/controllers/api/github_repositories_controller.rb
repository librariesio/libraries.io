class Api::GithubRepositoriesController < Api::ApplicationController
  before_action :check_api_key, :find_repo, except: :search

  def show
    render json: @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
  end

  def projects
    paginate json: @github_repository.projects.includes(:versions, :github_repository).as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end

  def dependencies
    dependencies = @github_repository.repository_dependencies || []

    deps = dependencies.map do |dependency|
      {
        project_name: dependency.project_name,
        name: dependency.project_name,
        platform: dependency.platform,
        requirements: dependency.requirements,
        latest_stable: dependency.try(:project).try(:latest_stable_release_number),
        latest: dependency.try(:project).try(:latest_release_number),
        deprecated: dependency.try(:project).try(:is_deprecated?),
        outdated: dependency.outdated?
      }
    end

    repo_json = @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
    repo_json[:dependencies] = deps

    render json: repo_json
  end

  def search
    @search = paginate GithubRepository.search(params[:q], filters: {
      license: current_licenses,
      language: current_languages,
      keywords: current_keywords
    }, sort: format_sort, order: format_order)
    @github_repositories = @search.records
    render json: @github_repositories.as_json({ except: [:id, :github_organisation_id, :owner_id] })
  end

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @github_repository.nil?
  end
end
