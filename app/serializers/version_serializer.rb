class VersionSerializer < ActiveModel::Serializer
  attributes :number, :published_at

  belongs_to :post
end
