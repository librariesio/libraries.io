require 'pry'

module PackageManager
  class Conda < Base
    # TODO: https://github.com/librariesio/conda-api/pull/2/files#diff-cc95738088603531796e0d0f246a5d77R16 get  this merged then figure out how to use it in Libraries.
    def self.project_names; end

    def self.project(name); end

    def self.mapping(project)
      {}
    end
  end
end
