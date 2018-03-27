class SourceRankCalculator
  def initialize(project)
    @project = project
  end

  def overall_score
    total_score/3.0
  end

  def popularity_score
    0
    # dependent_projects
    # dependent_repositories
    # stars
    # forks
    # watchers
  end

  def community_score
    0
    # recent_release
    # not_brand_new
    # contributors
    # code_of_conduct_present
    # contributing docs present
  end

  def quality_score
    0
    # basic_info_present
    # source repository_present
    # readme_present
    # license_present
    # multiple_versions_present
    # follows_semver
    # one_point_oh
    # all_prereleases
    # is_deprecated
    # is_unmaintained
    # is_removed

    # dependencies_score
  end

  private

  def dependencies_score
    # any_outdated_dependencies
  end

  def total_score
    popularity_score + community_score + quality_score
  end
end
