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
  rescue
    nil
  end

  def semantic_requirements
    case platform.downcase
    when 'elm'
      numbers = requirements.split('<= v')
      ">=#{numbers[0].strip} #{numbers[1].strip}"
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
    if date
      versions = versions.where('versions.published_at < ?', date)
    end
    version_numbers = versions.map {|v| SemanticRange.clean(v.number) }.compact
    number = SemanticRange.max_satisfying(version_numbers, semantic_requirements, false, platform)
    versions.find{|v| SemanticRange.clean(v.number) == number }
  end

  def update_project
    return unless project_name.present? && package_manager
    package_manager.update(project_name)
  end

  def package_manager
    PackageManager::Base.platforms.find{|pm| pm.formatted_name.downcase == platform.downcase }
  end
end
