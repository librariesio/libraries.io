class Api::RepositoriesController < Api::ApplicationController
  before_action :find_repo, except: :search

  def show
    render json: @repository.as_json({
      except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id]
    })
  end

  def projects
    paginate json: project_json_response(@repository.projects.includes(:versions, :repository))
  end

  def dependencies
    repo_json = @repository.as_json({
      except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id]
    })
    repo_json[:dependencies] = map_dependencies(@repository.repository_dependencies || [])

    render json: repo_json
  end

  def search
    @search = paginate(search_repos(params[:q]))
    @repositories = @search.records
    render json: @repositories.as_json({ except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id] })
  end

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join('/')
    @repository = Repository.host(current_host).open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @repository.nil?
  end

  def allowed_sorts
    ['rank', 'stargazers_count', 'github_contributions_count', 'created_at', 'pushed_at', 'subscribers_count', 'open_issues_count', 'forks_count', 'size']
  end
end
