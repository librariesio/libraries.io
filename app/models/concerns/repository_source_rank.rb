module RepositorySourceRank
  extend ActiveSupport::Concern

  def update_source_rank
    update_column :rank, source_rank
    touch
    __elasticsearch__.index_document
  end

  def update_source_rank_async
    UpdateRepositorySourceRankWorker.perform_async(self.id) if updated_at.present? && updated_at < 1.day.ago
  end

  def set_source_rank
    self.rank = source_rank
  end

  def source_rank
    source_rank_breakdown.values.sum > 0 ? source_rank_breakdown.values.sum : 0
  end

  def source_rank_breakdown
    @source_rank_breakdown ||= {
      basic_info_present:         basic_info_present? ? 1 : 0,
      readme_present:             readme_present? ? 1 : 0,
      license_present:            license_present? ? 1 : 0,
      recently_pushed:            recently_pushed? ? 1 : 0,
      not_brand_new:              not_brand_new? ? 1 : 0,
      dependent_projects:         log_scale(dependent_projects_count) * 2,
      dependent_repositories:     log_scale(dependent_repos_count),
      github_stars:               log_scale(stars),
      contributors:               (log_scale(github_contributions_count) / 2.0).ceil,
      any_outdated_dependencies:  any_outdated_dependencies? ? -1 : 0,
      is_deprecated:              is_deprecated? ? -5 : 0,
      is_unmaintained:            is_unmaintained? ? -5 : 0,
      is_removed:                 is_removed? ? -5 : 0
    }
  end

  def basic_info_present?
    [description.presence, homepage.presence].compact.length > 1
  end

  def readme_present?
    readme.present?
  end

  def dependent_projects_count
    projects.map(&:dependents_count).sum || 0
  end

  def dependent_repos_count
    projects.map(&:dependent_repos_count).sum || 0
  end

  def license_present?
    license.present?
  end

  def recently_pushed?
    pushed_at && pushed_at > 6.months.ago
  end

  def not_brand_new?
    created_at && created_at < 6.months.ago
  end

  def any_outdated_dependencies?
    dependencies.any?(&:outdated?)
  end

  def log_scale(number)
    return 0 if number <= 0
    Math.log10(number).round
  end
end
