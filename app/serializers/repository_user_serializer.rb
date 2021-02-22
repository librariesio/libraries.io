# frozen_string_literal: true
class RepositoryUserSerializer < ActiveModel::Serializer
  attributes :github_id, :login, :user_type, :created_at, :updated_at, :name,
             :company, :blog, :location, :hidden, :last_synced_at, :email, :bio,
             :uuid, :host_type
end
