# frozen_string_literal: true

class RepositoryPermission < ApplicationRecord
  belongs_to :user
  belongs_to :repository

  validates_uniqueness_of :repository_id, scope: :user_id
end
