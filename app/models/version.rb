class Version < ActiveRecord::Base
  validates_presence_of :project_id, :number

  belongs_to :project
end
