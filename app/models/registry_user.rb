class RegistryUser < ApplicationRecord
  has_many :registry_permissions
  has_many :projects, through: :registry_permissions

  def download_projects
    return unless platform.downcase == 'rubygems'

    projects = PackageManager::Base.get_json("https://rubygems.org/api/v1/owners/#{login}/gems.json")

    projects.each do |project|
      PackageManager::Rubygems.update(project['name'])
    end
  end
end
