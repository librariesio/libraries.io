# frozen_string_literal: true

module DependencyChecks
  extend ActiveSupport::Concern

  def incompatible_license?
    compatible_license? == false
  end

  def outdated?
    return nil unless valid_requirements? && project && project.latest_stable_release_number

    !(SemanticRange.satisfies(SemanticRange.clean(project.latest_stable_release_number), semantic_requirements, false, platform) ||
      SemanticRange.satisfies(SemanticRange.clean(project.latest_release_number), semantic_requirements, false, platform) ||
      SemanticRange.ltr(SemanticRange.clean(project.latest_release_number), semantic_requirements, false, platform))
  rescue StandardError
    nil
  end

  def semantic_requirements
    case platform.downcase
    when "elm"
      numbers = requirements.split("<= v")
      ">=#{numbers[0].strip} #{numbers[1].strip}"
    when "pypi"
      requirements&.remove(/[()]/) # remove parentheses surrounding version requirement
    else
      requirements
    end
  end

  def valid_requirements?
    !!SemanticRange.valid_range(semantic_requirements)
  end

  def latest_resolvable_version(date = nil)
    return nil unless project.present?

    versions = project.versions
    versions = versions.where("versions.published_at < ?", date) if date
    version_numbers = versions.map { |v| SemanticRange.clean(v.number) }.compact
    number = SemanticRange.max_satisfying(version_numbers, semantic_requirements, false, platform)
    return nil unless number.present?

    versions.find { |v| SemanticRange.clean(v.number) == number }
  end

  def update_project
    return unless project_name.present? && package_manager

    package_manager.update(project_name, source: "DependencyChecks#update_project")
  end

  def package_manager
    PackageManager::Base.find(platform)
  end
end
