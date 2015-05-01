class Manifest < ActiveRecord::Base
  belongs_to :github_repository
  # has many deps
end
