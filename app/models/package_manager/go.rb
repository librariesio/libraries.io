# frozen_string_literal: true

module PackageManager
  class Go < Base
    HAS_VERSIONS = true
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
      "https://pkg.go.dev/#{project.name}#{"@#{version}" if version}"
    end

    def self.documentation_url(name, version = nil)
      "https://pkg.go.dev/#{name}#{"@#{version}" if version}?tab=doc"
    end

    def self.install_instructions(project, version = nil)
      "go get #{project.name}"
    end

    def self.project_names
      # Currently the index only shows the last <=2000 modules from the date given. (https://proxy.golang.org/)
      project_window = 1.day.ago.strftime("%FT%TZ")
      get_raw("https://index.golang.org/index?since=#{project_window}&limit=2000")
        .lines
        .map { |line| JSON.parse(line)["Path"] }
    end

    def self.project(name)
      if pkg_html = get_html("https://pkg.go.dev/#{name}?tab=doc")
        go_module, _latest_version = pkg_html.css('a[data-test-id="DetailsHeader-infoLabelModule"]').first&.text&.split('@', 2)
        go_module_html = get_html("https://pkg.go.dev/mod/#{go_module}")
        # NB this requires a quick request for each version, but we could alternatively fetch from
        # https://pkg.go.dev/mod/#{go_module}?tab=versions and the '.Versions-commitTime', selector,
        # but the dates are a combination of date-only or natural language (e.g. '1 day ago')
        versions = get_raw("http://proxy.golang.org/#{go_module}/@v/list")
          &.lines
          &.map(&:strip)
          &.reject(&:blank?)
          &.map do |v|
            info = get("http://proxy.golang.org/#{go_module}/@v/#{v}.info")
            {
              number: info["Version"],
              published_at: info["Time"].presence && Time.parse(info["Time"])
            }
          end

        { name: name, go_module: go_module, html: pkg_html, go_module_html: go_module_html, versions: versions }
      else
        { name: name }
      end
    rescue => e
      puts caller
      raise e
    end

    def self.versions(project, name)
      return [] if project.nil?
      return project[:versions]
    end

    def self.mapping(project)
      if project[:html]
        {
          name: project[:name],
          description: project[:html].css('.Documentation-overview p').map(&:text).join("\n").strip,
          licenses: project[:go_module_html].css('*[data-test-id="DetailsHeader-infoLabelLicense"] a').map(&:text),
          repository_url: project[:go_module_html].css('.Overview-sourceCodeLink a').first&.text,
          homepage: project[:go_module_html].css('.Overview-sourceCodeLink a').first&.text,
          versions: project[:versions]
        }
      else
        { name: project[:name] }
      end
    end

    # https://golang.org/cmd/go/#hdr-Import_path_syntax
    def self.project_find_names(name)
      return [name] if name.start_with?(*KNOWN_HOSTS)
      return [name] if KNOWN_VCS.any?(&name.method(:include?))

      go_import = get_html('https://' + name + '?go-get=1')
        .xpath('//meta[@name="go-import"]')
        .first
        &.attribute("content")
        &.value
        &.split(" ")
        &.last
        &.sub(/https?:\/\//, "")

      go_import&.start_with?(*KNOWN_HOSTS) ? [go_import] : [name]
    end

    def self.get_repository_url(project)
      request("https://#{project['Package']}").to_hash[:url].to_s
    end
  end
end
