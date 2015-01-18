class GithubRepository < ActiveRecord::Base
  # validations (presense and uniqueness)

  belongs_to :project
end
