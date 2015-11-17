class ProjectSuggestion < ActiveRecord::Base
  validates_presence_of :user, :project, :notes

  belongs_to :user
  belongs_to :project
end
