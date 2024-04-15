# frozen_string_literal: true

class DependencySerializer < ActiveModel::Serializer
  # NB: filepath is deprecated as we're only pulling deps from projects instead of repos now.
  attributes :project_name, :name, :platform, :requirements, :latest_stable, :latest,
             :deprecated, :outdated, :filepath, :kind, :optional, :normalized_licenses

  def normalized_licenses
    object.project.try(:normalized_licenses)
  end
end
