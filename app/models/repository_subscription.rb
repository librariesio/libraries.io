class RepositorySubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :github_repository
end
