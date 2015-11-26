class Api::DocsController < ApplicationController
  before_action :ensure_logged_in

  def index
    @project = Project.platform('npm').find_by_name('grunt') || Project.platform('rubygems').first

    @version = @project.versions.newest_first.first

    dependencies = @version.dependencies || []

    deps = dependencies.map do |dependency|
      {
        project_name: dependency.project_name,
        platform: dependency.platform,
        requirements: dependency.requirements,
        latest_stable: dependency.try(:project).try(:latest_stable_release_number),
        latest: dependency.try(:project).try(:latest_release_number),
        deprecated: dependency.try(:project).try(:is_deprecated?),
        outdated: dependency.outdated?
      }
    end

    @dependencies = @project.as_json(only: [:name, :platform, :description, :language, :homepage, :repository_url,  :normalized_licenses])
    @dependencies[:dependencies] = deps

    @github_repository = GithubRepository.find_by_full_name('gruntjs/grunt') || GithubRepository.first

    @repo_dependencies = []

    dependencies = @github_repository.repository_dependencies || []

    deps = dependencies.map do |dependency|
      {
        project_name: dependency.project_name,
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
  end
end
