class Api::DocsController < ApplicationController
  skip_before_action :check_api_key, raise: false

  def index
    @cache_version = 'v1.1'
    @api_key = logged_in? ? current_user.api_key : 'YOUR_API_KEY'
    @project = Project.platform('npm').includes(:versions, :github_repository).find_by_name('base62') || Project.platform('rubygems').first

    @version = @project.versions.first

    dependencies = @version.dependencies || []

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

    @dependencies = @project.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords])
    @dependencies[:dependencies] = deps

    @github_repository = GithubRepository.find_by_full_name('gruntjs/grunt') || GithubRepository.first

    @repo_dependencies = []

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

    @repo_dependencies = @github_repository.as_json({
      except: [:id, :github_organisation_id, :owner_id]
    })
    @repo_dependencies[:dependencies] = deps

    @search = Project.search('grunt').records

    @github_user = GithubUser.find_by_login('andrew')
  end
end
