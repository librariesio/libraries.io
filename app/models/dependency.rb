class Dependency < ActiveRecord::Base
  belongs_to :version
  belongs_to :project#, touch: true

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("project_name <> ''") }
  scope :kind, ->(kind) { where(kind: kind) }

  after_create :update_project_id

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.downcase.strip).limit(1).pluck(:id).first
  end

  def incompatible_license?
    compatible_license? == false
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if version.project.normalized_licenses.empty?
    project.normalized_licenses.any? do |license|
      version.project.normalized_licenses.any? do |other_license|
        begin
          License::Compatibility.forward_compatiblity(license, other_license)
        rescue
          true
        end
      end
    end
  end

  def platform
    plat = self.read_attribute(:platform)
    case plat
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
      plat
    end
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end

  def valid_requirements?
    !!SemanticRange.valid_range(requirements)
  end

  def outdated?
    return nil unless valid_requirements? && project && project.latest_stable_release_number
    !SemanticRange.satisfies(project.latest_stable_release_number, requirements)
  rescue
    nil
  end

  def latest_resolvable_version
    versions = project.versions
    version_numbers = versions.map {|v| SemanticRange.clean(v.number) }
    number = SemanticRange.max_satisfying(version_numbers, requirements)
    versions.find{|v| SemanticRange.clean(v.number) == number }
  end
end
