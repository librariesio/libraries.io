class Dependency < ActiveRecord::Base
  belongs_to :version, touch: true
  belongs_to :project, touch: true

  validates_presence_of :project_name, :version_id, :requirements, :platform
end
