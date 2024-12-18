# frozen_string_literal: true

class VersionSerializer < ActiveModel::Serializer
  attributes :number, :published_at, :spdx_expression, :original_license, :researched_at, :repository_sources

  belongs_to :project

  def repository_sources
    object.repository_sources.presence || [object.project.platform]
  end
end
