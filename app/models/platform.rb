# frozen_string_literal: true

class Platform
  include ActiveModel::Model
  include ActiveModel::Serialization
  attr_accessor :name, :project_count

  def self.all
    Project
      .maintained
      .where.not(platform: ProjectSearch::REMOVED_PLATFORMS)
      .group(:platform)
      .order("count_id DESC")
      .count("id")
      .map do |key, count|
        Platform.new(name: key, project_count: count)
      end
  end

  delegate :formatted_name, :color, :homepage, :default_language, to: :package_manager

  private

  def package_manager
    "PackageManager::#{name}".constantize
  end
end
