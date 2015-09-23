class Dependency < ActiveRecord::Base
  belongs_to :version
  belongs_to :project, touch: true

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :without_project_id, -> { where(project_id: nil) }

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.downcase).limit(1).pluck(:id).first
  end

  def platform
    plat = self.read_attribute(:platform)
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
