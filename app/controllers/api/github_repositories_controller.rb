class Api::GithubRepositoriesController < Api::ApplicationController
  before_action :find_repo, except: :search

  def show
    render json: @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
  end

  def projects
    paginate json: @github_repository.projects.includes(:versions, :github_repository).as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end

  def dependencies
    repo_json = @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
    repo_json[:dependencies] = map_dependencies(@github_repository.repository_dependencies || [])

    render json: repo_json
  end

  def search
    @search = paginate(search_repos(params[:q]))
    @github_repositories = @search.records
    render json: @github_repositories.as_json({ except: [:id, :github_organisation_id, :owner_id] })
  end

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @github_repository.nil?
  end

  def allowed_sorts
    ['stargazers_count', 'github_contributions_count', 'created_at', 'pushed_at', 'subscribers_count', 'open_issues_count', 'forks_count', 'size']
  end
end
