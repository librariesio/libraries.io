module SourcerankHelper
  def source_rank_badge_class(value)
    if value > 0
      'alert-success'
    elsif value < 0
      'alert-danger'
    else
      'alert-warning'
    end
  end

  def source_rank_titles
    {
      basic_info_present:         'Basic info present?',
      repository_present:         'GitHub repository present?',
      readme_present:             'Readme present?',
      license_present:            'License present?',
      versions_present:           'Has multiple versions?',
      follows_semver:             'Follows SemVer?',
      recent_release:             'Recent release?',
      not_brand_new:              'Not brand new?',
      is_deprecated:              'Deprecated?',
      is_unmaintained:            'Unmaintained?',
      is_removed:                 'Removed?',
      any_outdated_dependencies:  'Outdated dependencies?',
      one_point_oh:               '1.0.0 or greater?',
      all_prereleases:            'Prerelease?',
      github_stars:               'GitHub stars',
      dependent_projects:         'Dependent Projects',
      dependent_repositories:     'Dependent Repositories',
      contributors:               'Contributors',
      subscribers:                'Libraries.io subscribers'
    }
  end

  def source_rank_explainations
    {
      basic_info_present:         'Description, homepage/repository link and keywords present?',
      versions_present:           'Has the project had more than one release?',
      follows_semver:             'Every version has a valid SemVer number',
      recent_release:             'Within the past 6 months?',
      not_brand_new:              'Existed for at least 6 months',
      is_deprecated:              'Marked as deprecated by the maintainer',
      is_unmaintained:            'Marked as unmaintained by the maintainer',
      is_removed:                 'Removed from the package manager',
      all_prereleases:            'All versions are prerelease',
      any_outdated_dependencies:  'At least one dependency is behind the latest version',
      github_stars:               'Logarithmic scale',
      dependent_projects:         'Logarithmic scale times two',
      dependent_repositories:     'Logarithmic scale',
      contributors:               'Logarithmic scale divided by two',
      subscribers:                'Logarithmic scale divided by two'
    }
  end
end
