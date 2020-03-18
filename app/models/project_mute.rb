# frozen_string_literal: true

class ProjectMute < ApplicationRecord
  validates_presence_of :project_id, :user_id
  validates_uniqueness_of :project_id, scope: :user_id

  belongs_to :user
  belongs_to :project
end
