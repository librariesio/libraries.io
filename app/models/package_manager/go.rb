# frozen_string_literal: true

module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SUPPORTS_SINGLE_VERSION_UPDATE = true
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
    DISCOVER_URL = "https://pkg.go.dev"
    URL = DISCOVER_URL

    VERSION_MODULE_REGEX = /(.+)\/(v\d+)/.freeze

    def self.check_status_url(db_project)
      "#{PROXY_BASE_URL}/#{encode_for_proxy(db_project.name)}/@v/list"
    end

    def self.package_link(db_project, version = nil)
      "#{DISCOVER_URL}/#{db_project.name}#{"@#{version}" if version}"
    end

    def self.documentation_url(name, version = nil)
      "#{DISCOVER_URL}/#{name}#{"@#{version}" if version}#section-documentation"
    end

    def self.install_instructions(db_project, _version = nil)
      "go get #{db_project.name}"
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

    def self.one_version(raw_project, version_string)
      info = get("#{PROXY_BASE_URL}/#{encode_for_proxy(raw_project[:name])}/@v/#{version_string}.info")

      # Store nil published_at for known Go Modules issue where case-insensitive name collisions break go get
      # e.g. https://proxy.golang.org/github.com/ysweid/aws-sdk-go/@v/v1.12.68.info
      version_string = info.nil? ? version_string : info["Version"]
      published_at = info && info["Time"].presence && Time.parse(info["Time"])
      data = {
        number: version_string,
        published_at: published_at,
      }

      # Supplement with license info from pkg.go.dev
      doc_html = get_html("#{DISCOVER_URL}/#{raw_project[:name]}")
      data[:original_license] = doc_html.css('*[data-test-id="UnitHeader-license"]').map(&:text).join(",")

      data
    end

    def self.update(name, sync_version: :all)
      project = super(name, sync_version: sync_version)
      # call update on base module name if the name is appended with major version
      # example: github.com/myexample/modulename/v2
      # use the returned project name in case it finds a Project via repository_url
      update_base_module(project.name) if project.name.match(VERSION_MODULE_REGEX)

      project
    end

    def self.update_base_module(name)
      matches = name.match(VERSION_MODULE_REGEX)

      PackageManagerDownloadWorker.perform_async(self.name, matches[1])

      module_project = Project.find_by(platform: "Go", name: name)
      base_module_project = Project.find_by(platform: "Go", name: matches[1])
      return if module_project.nil? || base_module_project.nil?

      # find any versions the /vx module knows about that the base module does have already
      new_base_versions = module_project.versions.where.not(number: base_module_project.versions.pluck(:number))

      new_base_versions.each do |vers|
        base_module_project.versions.create(number: vers.number, published_at: vers.published_at, original_license: vers.original_license)
      end
    end

    def self.project(name)
      # get_html will send back an empty string if response is not a 200
      # a blank response means that the project was not found on pkg.go.dev site
      # if it is not found on that site it should be considered an invalid project name
      # although the go proxy may respond with data for this project name
      doc_html = get_html("#{DISCOVER_URL}/#{name}")

      # send back nil if the response is blank
      # base package manager handles if the project is not present
      { name: name, html: doc_html, overview_html: doc_html } unless doc_html.text.blank?
    end

    def self.versions(raw_project, _name)
      return [] if raw_project.nil?
      return raw_project[:versions] if raw_project[:versions]

      known_versions = Project.find_by(platform: "Go", name: raw_project[:name])&.versions&.select(:number, :created_at, :published_at, :updated_at, :original_license)&.index_by(&:number) || {}

      # NB fetching versions from the html only gets dates without timestamps, but we could alternatively use the go proxy too:
      #   1) Fetch the list of versions: https://proxy.golang.org/#{module_name}/@v/list
      #   2) And for each version, fetch https://proxy.golang.org/#{module_name}/@v/#{v}.info
      get_raw("#{PROXY_BASE_URL}/#{encode_for_proxy(raw_project[:name])}/@v/list")
        &.lines
        &.map(&:strip)
        &.reject(&:blank?)
        &.map do |v|
          known = known_versions[v]

          if known && known[:original_license].present?
            known.slice(:number, :created_at, :published_at, :original_license)
          else
            one_version(raw_project, v)
          end
      rescue Oj::ParseError
        next
        end
        &.compact
    end

    def self.mapping(raw_project)
      if raw_project[:html]
        url = raw_project[:overview_html]&.css(".UnitMeta-repo a")&.first&.attribute("href")&.value

        # find an existing project with the same repository and replace the name with the existing project
        # this will avoid creating duplicate Projects with various casing

        # if this is a versioned module, make sure to find the right versioned project
        regex_matches = raw_project[:name].match(VERSION_MODULE_REGEX)
        if regex_matches
          # try and find a versioned name matching this repository_url
          existing_project_name = Project.where(platform: "Go").where("lower(repository_url) = :repo_url and name like :name", repo_url: url.downcase, name: "%/#{regex_matches[2]}").first&.name

          # if we didn't find one then try and get the base project
          unless existing_project_name.present?
            versioned_name = Project.where(platform: "Go").where("lower(repository_url) = ? and name not like '%/v'", url.downcase).first&.name
            existing_project_name = versioned_name&.concat("/#{regex_matches[2]}")
          end
        else
          existing_project_name = Project.where(platform: "Go").where("lower(repository_url) = ?", url.downcase).first&.name
        end

        {
          name: existing_project_name.presence || raw_project[:name],
          description: raw_project[:html].css(".Documentation-overview p").map(&:text).join("\n").strip,
          licenses: raw_project[:html].css('*[data-test-id="UnitHeader-license"]').map(&:text).join(","),
          repository_url: url,
          homepage: url,
        }
      else
        { name: raw_project[:name] }
      end
    end

    def self.dependencies(name, version, _mapped_project)
      # Go proxy spec: https://golang.org/cmd/go/#hdr-Module_proxy_protocol
      # TODO: this can take up to 2sec if it's a cache miss on the proxy. Might be able
      # to scrape the webpage or wait for an API for a faster fetch here.
      resp = request("#{PROXY_BASE_URL}/#{encode_for_proxy(name)}/@v/#{version}.mod")
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
        go_import = get_html("https://#{name}?go-get=1")
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

    def self.valid_project?(name)
      response = request("#{DISCOVER_URL}/#{name}")
      response.status == 200
    end

    # will convert a string with capital letters and replace with a "!" prepended to the lowercase letter
    # this is needed to follow the goproxy protocol and find versions correctly for modules with capital letters in them
    # https://go.dev/ref/mod#goproxy-protocol
    def self.encode_for_proxy(str)
      str.gsub(/[A-Z]/) { |s| "!#{s.downcase}" }
    end
  end
end
