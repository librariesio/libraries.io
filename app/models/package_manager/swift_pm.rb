# frozen_string_literal: true
module PackageManager
  class SwiftPM < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://developer.apple.com/swift/'
    COLOR = '#ffac45'

    def self.project_names
      @project_names ||= `rm -rf swift-package-crawler-data;git clone https://github.com/czechboy0/swift-package-crawler-data.git --depth 1; ls swift-package-crawler-data/PackageJSONFiles`.split("\n")
    end

    def self.project(name)
      name_with_owner = name.gsub("-Package.json", "").split('_').join('/')
      {
        name: "github.com/#{name_with_owner}",
        repository_url: "https://github.com/#{name_with_owner}"
      }
    end

    def self.mapping(raw_project)
      {
        name: raw_project[:name],
        repository_url: raw_project[:repository_url]
      }
    end
  end
end
