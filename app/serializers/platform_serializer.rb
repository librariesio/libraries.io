# frozen_string_literal: true

class PlatformSerializer < ActiveModel::Serializer
  attributes :name, :project_count, :homepage, :color, :default_language
end
