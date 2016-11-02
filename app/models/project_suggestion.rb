class ProjectSuggestion < ActiveRecord::Base
  validates_presence_of :user, :project, :notes

  belongs_to :user
  belongs_to :project

  def done?
    !pending
  end

  def pending
    (repository_url.present? && repository_url != project.try(:repository_url)) ||
    (licenses.present? && licenses != project.try(:licenses)) ||
    (status.present? && status != project.try(:status))
  end
end
