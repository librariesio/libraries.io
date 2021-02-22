# frozen_string_literal: true
class RepositoryMaintenanceStatSerializer < ActiveModel::Serializer
  attributes :category, :value, :updated_at
end
