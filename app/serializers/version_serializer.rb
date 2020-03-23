# frozen_string_literal: true

class VersionSerializer < ActiveModel::Serializer
  attributes :number, :published_at, :spdx_expression, :original_license

  belongs_to :project
end
