# frozen_string_literal: true

class RepositoryUpdatedSerializer < ActiveModel::Serializer
  attributes %i[
    full_name
    host_type
    name
    updated_at
    url
  ]
end
