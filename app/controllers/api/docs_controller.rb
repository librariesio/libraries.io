class Api::DocsController < ApplicationController
  skip_before_action :check_api_key, raise: false

  def index
    @cache_version = 'v1.1'
    @api_key = logged_in? ? current_user.api_key : 'YOUR_API_KEY'
    @project = Project.platform('npm').visible.includes(:versions, :repository).find_by_name('base62') || Project.platform('rubygems').visible.first

    @version = @project.versions.sort.first

    @dependencies = @project.as_json
    @dependencies[:dependencies] = map_dependencies(@version.dependencies || [])

    @dependent_projects = @project.dependent_projects.paginate(page: 1)

    @repository = Repository.host('GitHub').find_by_full_name('gruntjs/grunt') || Repository.host('GitHub').first

    @repo_dependencies = @repository.as_json

    @repo_dependencies[:dependencies] = map_dependencies(@repository.repository_dependencies || [])

    @search = Project.search('grunt', api: true).records

    @repository_user = RepositoryUser.host('GitHub').login('andrew').first || RepositoryUser.first
  end
end
