# frozen_string_literal: true
class Platform
  include ActiveModel::Model
  include ActiveModel::Serialization
  attr_accessor :name, :project_count

  def self.all
    Project.popular_platforms.map do |platform|
      Platform.new(name: platform['key'], project_count: platform['doc_count'])
    end
  end

  delegate :formatted_name, :color, :homepage, :default_language, to: :package_manager

  private

  def package_manager
    "PackageManager::#{name}".constantize
  end
end
