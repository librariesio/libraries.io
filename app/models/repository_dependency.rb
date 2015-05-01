class RepositoryDependency < ActiveRecord::Base
  belongs_to :manifest
  belongs_to :project
end
