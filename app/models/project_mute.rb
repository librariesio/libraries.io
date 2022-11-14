# frozen_string_literal: true

# == Schema Information
#
# Table name: project_mutes
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_project_mutes_on_project_id_and_user_id  (project_id,user_id) UNIQUE
#
class ProjectMute < ApplicationRecord
  validates_presence_of :project_id, :user_id
  validates_uniqueness_of :project_id, scope: :user_id

  belongs_to :user
  belongs_to :project
end
