# frozen_string_literal: true

module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://pkg.go.dev/"
    COLOR = "#375eab"
    KNOWN_HOSTS = [
      "bitbucket.org",
      "github.com",
      "launchpad.net",
      "hub.jazz.net",
    ].freeze
    KNOWN_VCS = [
      ".bzr",
      ".fossil",
      ".git",
      ".hg",
      ".svn",
    ].freeze
    PROXY_BASE_URL = "https://proxy.golang.org"

    VERSION_MODULE_REGEX = /(.+)\/(v\d+)/.freeze

    def self.package_link(project, version = nil)
      "https://pkg.go.dev/#{project.name}#{"@#{version}" if version}"
    end

    def self.documentation_url(name, version = nil)
      "https://pkg.go.dev/#{name}#{"@#{version}" if version}#section-documentation"
    end

    def self.install_instructions(project, _version = nil)
      "go get #{project.name}"
    end

    def self.recent_names
      project_names(1.day.ago)
    end

    def self.project_names(since = 1.day.ago)
      # Currently the index only shows the last <=2000 package version releases from the date given. (https://proxy.golang.org/)
      project_window = since.strftime("%FT%TZ")
      get_raw("https://index.golang.org/index?since=#{project_window}&limit=2000")
        .lines
        .map { |line| JSON.parse(line)["Path"] }
    end

    def self.update(name)
      super(name)
      # call update on base module name if the name is appended with major version
      # example: github.com/myexample/modulename/v2
      update_base_module(name) if name.match(VERSION_MODULE_REGEX)
    end

    def self.update_base_module(name)
      matches = name.match(VERSION_MODULE_REGEX)

      PackageManagerDownloadWorker.perform_async(self.name, matches[1])

      module_project = Project.find_by(platform: "Go", name: name)
      base_module_project = Project.find_by(platform: "Go", name: matches[1])
      return if module_project.nil? || base_module_project.nil?

      # find any versions the /vx module knows about that the base module does have already
      new_base_versions = module_project.versions.where.not(number: base_module_project.versions.pluck(:number))

      new_base_versions.each do |version|
        base_module_project.versions.create(number: version.number, published_at: version.published_at)
      end
    end

    def self.project(name)
      if (doc_html = get_html("https://pkg.go.dev/#{name}"))
        { name: name, html: doc_html, overview_html: doc_html }
      else
        { name: name }
      end
    end

    def self.versions(project, _name)
      return [] if project.nil?
      return project[:versions] if project[:versions]

      known_versions = Project
        .find_by(platform: "Go", name: project[:name])
        &.versions
        &.select(:number, :published_at)
        &.to_h || {}

      # NB fetching versions from the html only gets dates without timestamps, but we could alternatively use the go proxy too:
      #   1) Fetch the list of versions: https://proxy.golang.org/#{module_name}/@v/list
      #   2) And for each version, fetch https://proxy.golang.org/#{module_name}/@v/#{v}.info

      get_raw("#{PROXY_BASE_URL}/#{project[:name]}/@v/list")
        &.lines
        &.map(&:strip)
        &.reject(&:blank?)
        &.map do |v|
          return known_versions[v].slice(:number, :published_at) if known_versions.key?(v)

          info = get("#{PROXY_BASE_URL}/#{project[:name]}/@v/#{v}.info")
          {
            number: info["Version"],
            published_at: info["Time"].presence && Time.parse(info["Time"]),
          }
        rescue Oj::ParseError
          next
        end
        &.compact
    end

    def self.mapping(project)
      if project[:html]
        {
          name: project[:name],
          description: project[:html].css(".Documentation-overview p").map(&:text).join("\n").strip,
          licenses: project[:html].css('*[data-test-id="UnitHeader-license"]').map(&:text).join(","),
          repository_url: project[:overview_html]&.css(".UnitMeta-repo")&.first&.next_element&.attribute("href")&.value,
          homepage: project[:overview_html]&.css(".UnitMeta-repo")&.first&.next_element&.attribute("href")&.value,
          versions: versions(project, project[:name]),
        }
      else
        { name: project[:name] }
      end
    end

    def self.dependencies(name, version, _project)
      # Go proxy spec: https://golang.org/cmd/go/#hdr-Module_proxy_protocol
      # TODO: this can take up to 2sec if it's a cache miss on the proxy. Might be able
      # to scrape the webpage or wait for an API for a faster fetch here.
      resp = request("#{PROXY_BASE_URL}/#{name}/@v/#{version}.mod")
      if resp.status == 200
        go_mod_file = resp.body
        Bibliothecary::Parsers::Go.parse_go_mod(go_mod_file)
          .map do |dep|
            {
              project_name: dep[:name],
              requirements: dep[:requirement],
              kind: dep[:type],
              platform: "Go",
            }
          end
      else
        []
      end
    end

    # https://golang.org/cmd/go/#hdr-Import_path_syntax
    def self.project_find_names(name)
      return [name] if name.start_with?(*KNOWN_HOSTS)
      return [name] if KNOWN_VCS.any?(&name.method(:include?))

      begin
        go_import = get_html("https://" + name + "?go-get=1")
          .xpath('//meta[@name="go-import"]')
          .first
          &.attribute("content")
          &.value
          &.split(" ")
          &.last
          &.sub(/https?:\/\//, "")

        go_import&.start_with?(*KNOWN_HOSTS) ? [go_import] : [name]
      rescue StandardError
        [name]
      end
    end

    def self.get_repository_url(project)
      request("https://#{project['Package']}").to_hash[:url].to_s
    end
  end
end
