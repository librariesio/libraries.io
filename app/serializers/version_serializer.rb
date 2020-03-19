class VersionSerializer < ActiveModel::Serializer
  attributes :number, :published_at, :spdx_expression

  belongs_to :project
end
