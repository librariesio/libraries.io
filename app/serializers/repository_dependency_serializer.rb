class RepositoryDependencySerializer < ActiveModel::Serializer
  attributes :project_name, :name, :platform, :requirements, :latest_stable,
             :latest, :deprecated, :outdated, :filepath, :kind
end
