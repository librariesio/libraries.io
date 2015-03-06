class GithubTag < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :name, :sha, :github_repository
end
