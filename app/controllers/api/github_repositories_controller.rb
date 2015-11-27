class Api::GithubRepositoriesController < Api::ApplicationController
  before_action :check_api_key, :find_repo

  def show
    render json: @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
  end

  def projects
    render json: @github_repository.projects.paginate(page: params[:page]).as_json(only: [:name, :platform, :description, :language, :homepage, :repository_url,  :normalized_licenses], include: {versions: {only: [:number, :published_at]} })
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

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @github_repository.nil?
  end
end
