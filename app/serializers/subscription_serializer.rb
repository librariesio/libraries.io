class SubscriptionSerializer < ActiveModel::Serializer
  attributes :include_prerelease, :created_at, :updated_at

  belongs_to :project
end
