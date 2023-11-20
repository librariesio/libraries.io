# frozen_string_literal: true

class ProjectUpdatedSerializer < ActiveModel::Serializer
  attributes %i[
    name
    platform
    updated_at
  ]
end
