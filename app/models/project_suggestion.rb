class ProjectSuggestion < ActiveRecord::Base
  validates_presence_of :user, :project, :notes

  belongs_to :user
  belongs_to :project

  def done?
    !pending
  end

  def pending
    (repository_url.present? && repository_url != project.repository_url) ||
    (licenses.present? && licenses != project.licenses) ||
    (status.present? && status != project.status)
  end
end
