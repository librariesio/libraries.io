class RepositoryPermission < ApplicationRecord
  belongs_to :user
  belongs_to :repository, foreign_key: "github_repository_id"

  validates_uniqueness_of :github_repository_id, scope: :user_id
end
