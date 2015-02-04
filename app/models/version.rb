class Version < ActiveRecord::Base
  validates_presence_of :project_id, :number
  # validate unique number and project_id
  belongs_to :project, touch: true

  def to_param
    project.to_param.merge(number: number)
  end

  def to_s
    number
  end
end
