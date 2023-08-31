# frozen_string_literal: true

namespace :export do
  task platform: :environment do
    require "csv"
    platform = ENV.fetch("PLATFORM")

    versions_file = File.open("#{platform}-versions.csv", "w")
    versions_csv = CSV.new(versions_file)
    versions_csv << ["Project name", "Version number", "Version date"]

    dependencies_file = File.open("#{platform}-dependencies.csv", "w")
    dependencies_csv = CSV.new(dependencies_file)
    dependencies_csv << ["Project name", "Version number", "Dependency name", "Dependency requirements", "Dependency kind"]

    Project.platform(platform).not_removed.includes(versions: :dependencies).find_each do |project|
      project.versions.each do |version|
        versions_csv << [project.name, version.number, version.published_at]
        version.dependencies.each do |dependency|
          dependencies_csv << [project.name, version.number, dependency.project_name, dependency.requirements, dependency.kind]
        end
      end
    end
  end
end
