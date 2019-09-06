require 'pry'

module PackageManager
  class Conda < Base
    def self.project_names; end

    def self.project(name); end

    def self.mapping(project)
      {}
    end
  end
end
