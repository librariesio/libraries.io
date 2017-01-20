class Api::GithubRepositoriesController < Api::ApplicationController
  before_action :find_repo, except: :search

  def show
    render json: @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
  end

  def projects
    paginate json: project_json_response(@github_repository.projects.includes(:versions, :github_repository))
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
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @github_repositories = @search.records.sort_by { |u| indexes[u.id] }
    render json: @github_repositories.as_json({ except: [:id, :github_organisation_id, :owner_id] })
  end

  private

  def find_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.open_source.where('lower(full_name) = ?', full_name.downcase).first

    raise ActiveRecord::RecordNotFound if @github_repository.nil?
  end

  def allowed_sorts
    ['rank', 'stargazers_count', 'github_contributions_count', 'created_at', 'pushed_at', 'subscribers_count', 'open_issues_count', 'forks_count', 'size']
  end
end
