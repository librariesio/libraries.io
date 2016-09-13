class RepositoryPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :github_repository

  validates_uniqueness_of :github_repository_id, scope: :user_id
end
