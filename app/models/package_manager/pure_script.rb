module PackageManager
  class PureScript < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_PLANNED = true
    URL = 'https://github.com/purescript/psc-package'
    COLOR = '#1D222D'

    def self.project_names
      get('https://raw.githubusercontent.com/purescript/package-sets/master/packages.json').keys
    end

    def self.project(name)
      project = get('https://raw.githubusercontent.com/purescript/package-sets/master/packages.json')[name]
      project['name'] = name

      project
    end

    def self.mapping(project)
      {
        :name => project['name'],
        :repository_url => project['repo']
      }
    end

    def self.install_instructions(project, version = nil)
      "psc-package install #{project.name}"
    end
  end
end
