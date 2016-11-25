module DependencyChecks
  extend ActiveSupport::Concern

  def incompatible_license?
    compatible_license? == false
  end

  def platform
    platform_name(read_attribute(:platform))
  end

  def platform_name(platform)
    case platform
    when 'rubygemslockfile', 'gemspec'
      'Rubygems'
    when 'cocoapodslockfile'
      'CocoaPods'
    when 'nugetlockfile', 'nuspec'
      'NuGet'
    when 'packagistlockfile'
      'Packagist'
    when 'npmshrinkwrap'
      'NPM'
    else
      platform
    end
  end

  def outdated?
    return nil unless valid_requirements? && project && project.latest_stable_release_number
    !(SemanticRange.satisfies(SemanticRange.clean(project.latest_stable_release_number), semantic_requirements) ||
      SemanticRange.satisfies(SemanticRange.clean(project.latest_release_number), semantic_requirements) ||
      SemanticRange.ltr(SemanticRange.clean(project.latest_release_number), semantic_requirements))
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
      p date
      versions = versions.where('versions.published_at < ?', date)
    end
    version_numbers = versions.map {|v| SemanticRange.clean(v.number) }.compact
    number = SemanticRange.max_satisfying(version_numbers, semantic_requirements)
    versions.find{|v| SemanticRange.clean(v.number) == number }
  end
end
