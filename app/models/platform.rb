# frozen_string_literal: true
class Platform
  include ActiveModel::Model
  include ActiveModel::Serialization
  attr_accessor :name, :project_count

  # Whenever a PackageManager::Base platform is removed, it's easier for now to
  # just add it to this list, until the records/indices are cleared out of that platform.
  # NB these are the casings from the database, which sometimes don't match the PackageManager::Base
  # formatted_name casings, e.g. Pypi vs PyPI
  REMOVED_PLATFORMS = %w(Sublime Wordpress Atom PlatformIO Shards Emacs Jam)

  def self.all
    Project
      .maintained
      .where.not(platform: ProjectSearch::REMOVED_PLATFORMS)
      .group(:platform)
      .order('count_id DESC')
      .count('id')
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
