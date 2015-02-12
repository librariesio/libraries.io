class Dependency < ActiveRecord::Base
  belongs_to :version
  belongs_to :project

  validates_presence_of :project_name, :version_id, :requirements, :platform
end
