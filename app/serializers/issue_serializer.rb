class IssueSerializer < ActiveModel::Serializer
  attributes :number, :state, :title, :body, :locked, :closed_at, :created_at,
             :updated_at

  belongs_to :repository
end
