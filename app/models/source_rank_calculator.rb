class SourceRankCalculator
  def initialize(project)
    @project = project
  end

  def overall_score
    total_score/3.0
  end

  def popularity_score
    popularity_scores.values.sum/popularity_scores.values.length.to_f

    # dependent_repositories
    # stars
    # forks
    # watchers
  end

  def community_score
    contribution_docs_score
    # recent_release
    # not_brand_new
    # contributors
    # maintainers
  end

  def quality_score
    basic_info_score
    # multiple_versions_present
    # follows_semver
    # one_point_oh
    # all_prereleases
    # is_deprecated
    # is_unmaintained
    # is_removed

    # dependencies_score
  end

  def basic_info_score
    basic_info.values.compact.length/basic_info.values.length.to_f*100
  end

  def contribution_docs_score
    contribution_docs.values.compact.length/contribution_docs.values.length.to_f*100
  end

  def dependent_projects_score
    return 0 if max_dependent_projects.to_f.zero?
    @project.dependents_count/max_dependent_projects.to_f*100
  end

  def dependent_repositories_score
    return 0 if max_dependent_repositories.to_f.zero?
    @project.dependent_repos_count/max_dependent_repositories.to_f*100
  end

  private

  def max_dependent_projects
    Project.platform(@project.platform).order('dependents_count DESC NULLS LAST').limit(1).pluck(:dependents_count).first
  end

  def max_dependent_repositories
    Project.platform(@project.platform).order('dependent_repos_count DESC NULLS LAST').limit(1).pluck(:dependent_repos_count).first
  end

  def dependencies_score
    # any_outdated_dependencies
  end

  def popularity_scores
    {
      dependent_projects: dependent_projects_score,
      dependent_repositories: dependent_repositories_score
    }
  end

  def basic_info
    {
      description:    @project.description.presence,
      homepage:       @project.homepage.presence,
      repository_url: @project.repository_url.presence,
      keywords:       @project.keywords.presence,
      readme:         @project.readme.presence,
      license:        @project.normalized_licenses.presence
    }
  end

  def contribution_docs
    {
      code_of_conduct: @project.has_coc.presence,
      contributing:    @project.has_contributing.presence,
      changelog:       @project.has_changelog.presence
    }
  end

  def total_score
    popularity_score + community_score + quality_score
  end
end
