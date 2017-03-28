class IssueSerializer < ActiveModel::Serializer
  attributes :name, :project_count, :homepage, :color, :default_language
end
