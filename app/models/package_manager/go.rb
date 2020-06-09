module PackageManager
  class Go < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'http://go-search.org/'
    COLOR = '#375eab'
    KNOWN_HOSTS = [
      'bitbucket.org',
      'github.com',
      'launchpad.net',
      'hub.jazz.net',
    ]
    KNOWN_VCS = [
      '.bzr',
      '.fossil',
      '.git',
      '.hg',
      '.svn',
    ]


    def self.package_link(project, version = nil)
      "http://go-search.org/view?id=#{project.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://godoc.org/#{name}"
    end

    def self.install_instructions(project, version = nil)
      "go get #{project.name}"
    end

    def self.project_names
      get("http://go-search.org/api?action=packages")
    end

    def self.project(name)
      get("http://go-search.org/api?action=package&id=#{name}")
    end

    def self.mapping(project)
      {
        name: project['Package'],
        description: project['Synopsis'],
        homepage: project['ProjectURL'],
        repository_url: get_repository_url(project)
      }
    end

    # https://golang.org/cmd/go/#hdr-Import_path_syntax
    def self.project_find_names(name)
      return [name] if name.start_with?(*KNOWN_HOSTS)
      return [name] if KNOWN_VCS.any?(&name.method(:include?))

      begin
        go_import = get_html('https://' + name + '?go-get=1')
          .xpath('//meta[@name="go-import"]')
          .first
          &.attribute("content")
          &.value
          &.split(" ")
          &.last
          &.sub(/https?:\/\//, "")

        go_import&.start_with?(*KNOWN_HOSTS) ? [go_import] : [name]
      rescue
        [name]
      end
    end

    def self.get_repository_url(project)
      request("https://#{project['Package']}").to_hash[:url].to_s
    end
  end
end
