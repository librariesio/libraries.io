# frozen_string_literal: true

class RepositoryOrganisationSerializer < ActiveModel::Serializer
  attributes :github_id, :login, :user_type, :created_at, :updated_at, :name,
             :company, :blog, :location, :hidden, :last_synced_at, :email, :bio,
             :followers, :following, :uuid, :host_type
end
