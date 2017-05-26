class IssueSerializer < ActiveModel::Serializer
  attributes :number, :state, :title, :body, :locked, :closed_at, :created_at,
             :updated_at, :uuid, :host_type

  belongs_to :repository
end
