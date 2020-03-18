# frozen_string_literal: true

class DependencySerializer < ActiveModel::Serializer
  attributes :project_name, :name, :platform, :requirements, :latest_stable,
             :latest, :deprecated, :outdated, :filepath, :kind, :normalized_licenses

  def normalized_licenses
    object.project.try(:normalized_licenses)
  end
end
