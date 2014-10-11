class Project < ActiveRecord::Base
  validates_presence_of :name, :platform

  ## relations
  # versions => dependencies
  # repository
  # licenses
  # users
end
