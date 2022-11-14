# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_permissions
#
#  id            :integer          not null, primary key
#  admin         :boolean
#  pull          :boolean
#  push          :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  repository_id :integer
#  user_id       :integer
#
# Indexes
#
#  user_repo_unique_repository_permissions  (user_id,repository_id) UNIQUE
#
class RepositoryPermission < ApplicationRecord
  belongs_to :user
  belongs_to :repository

  validates_uniqueness_of :repository_id, scope: :user_id
end
