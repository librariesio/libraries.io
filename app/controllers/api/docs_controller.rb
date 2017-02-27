class Api::DocsController < ApplicationController
  skip_before_action :check_api_key, raise: false

  def index
    @cache_version = 'v1.1'
    @api_key = logged_in? ? current_user.api_key : 'YOUR_API_KEY'
    @project = Project.platform('npm').includes(:versions, :repository).find_by_name('base62') || Project.platform('rubygems').first

    @version = @project.versions.first

    @dependencies = project_json_response(@project)
    @dependencies[:dependencies] = map_dependencies(@version.dependencies || [])

    @repository = Repository.host('GitHub').find_by_full_name('gruntjs/grunt') || Repository.host('GitHub').first

    @repo_dependencies = @repository.as_json({
      except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id]
    })
    @repo_dependencies[:dependencies] = map_dependencies(@repository.repository_dependencies || [])

    @search = Project.search('grunt').records

    @github_user = GithubUser.find_by_login('andrew') || GithubUser.first
  end
end
