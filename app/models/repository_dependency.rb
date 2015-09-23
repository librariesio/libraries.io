class RepositoryDependency < ActiveRecord::Base
  belongs_to :manifest
  belongs_to :project

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }

  def github_repository
    manifest.try(:github_repository)
  end

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.try(:downcase)).limit(1).pluck(:id).first
  end

  def platform
    plat = read_attribute(:platform)
    case plat
    when 'rubygemslockfile'
      'Rubygems'
    when 'cocoapodslockfile'
      'CocoaPods'
    when 'packagistlockfile'
      'Packagist'
    when 'gemspec'
      'Rubygems'
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
end
