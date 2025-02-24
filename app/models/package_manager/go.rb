# frozen_string_literal: true

module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    COLOR = "#375eab"
    PROXY_BASE_URL = "https://proxy.golang.org"
    DISCOVER_URL = "https://pkg.go.dev"
    URL = DISCOVER_URL

    VERSION_MODULE_REGEX = /(.+)\/(v\d+)(\/|$)/

    class UnknownGoType < StandardError
      def initialize(name, page_types)
        super("Unknown Go page type (it is neither a package, a directory, a command or a module) for #{name}: #{page_types.join(',')}")
      end
    end

    def self.missing_version_remover
      PackageManager::Go::GoMissingVersionRemover
    end

    def self.check_status_url(db_project)
      "#{DISCOVER_URL}/#{db_project.name}"
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
      info = get("#{PROXY_BASE_URL}/#{encode_for_proxy(raw_project[:name])}/@v/#{encode_for_proxy(version_string)}.info")

      # Store nil published_at for known Go Modules issue where case-insensitive name collisions break go get
      # e.g. https://proxy.golang.org/github.com/ysweid/aws-sdk-go/@v/v1.12.68.info
      version_string = info.nil? ? version_string : info["Version"]
      published_at = info && info["Time"].presence && Time.parse(info["Time"])

      # Supplement with license info from pkg.go.dev
      doc_html = get_html("#{DISCOVER_URL}/#{raw_project[:name]}")

      VersionBuilder.build_hash(
        number: version_string,
        published_at: published_at,
        original_license: doc_html.css('*[data-test-id="UnitHeader-license"]').map(&:text).join(",")
      )
    end

    def self.project(name)
      # Try and find the canonical name from the Go proxy and use that if we find it.
      # pkg.go.dev will sometimes have multiple cased names for the same project, but for
      # a project with a go.mod file specified the proxy should have the canonical name.
      # It is still possible for the proxy to return a non canonical name for a project
      # that is not a valid module. https://go.dev/ref/mod#goproxy-protocol describes
      # how a $base/$module/@v/$version.mod request will return back a virtual go.mod file
      # with whatever name was passed in if there is not a go.mod file found for that version.
      name_in_go_mod = name_in_go_mod(name)
      search_name = if name_in_go_mod.present?
                      if name.downcase.include?(name_in_go_mod.downcase)
                        name_in_go_mod
                      else
                        StructuredLog.capture(
                          "GO_PROJECT_NAME_DOES_NOT_MATCH_GO_MOD_NAME",
                          {
                            go_mod_name: name_in_go_mod,
                            project_name: name,
                            source: self.name,
                          }
                        )
                        name
                      end
                    else
                      name
                    end

      # get_html will send back an empty string if response is not a 200
      # a blank response means that the project was not found on pkg.go.dev site
      # if it is not found on that site it should be considered an invalid project name
      # although the go proxy may respond with data for this project name
      doc_html = get_html("#{DISCOVER_URL}/#{search_name}")

      # send back nil if the response is blank
      # base package manager handles if the project is not present
      return nil if doc_html.text.blank?

      raw_project = { name: search_name, html: doc_html, overview_html: doc_html }

      # pages on pkg.go.dev can be categorized as 'package', 'module', 'command', or 'directory'. We only scrape Go Modules.
      page_types = page_types(raw_project: raw_project)
      unless page_types.include?("module")
        # this is more for our record-keeping so we know what possible types there are.
        if %w[package command directory].none? { |t| page_types.include?(t) } && defined?(Bugsnag)
          Bugsnag.notify(UnknownGoType.new(name, page_types))
        end
        return nil
      end

      raw_project
    end

    def self.versions(raw_project, _name)
      return [] if raw_project.nil?
      return raw_project[:versions] if raw_project[:versions]

      known_versions = Project.find_by(platform: "Go", name: raw_project[:name])&.versions&.select(:number, :created_at, :published_at, :updated_at, :original_license)&.index_by(&:number) || {}

      # NB fetching versions from the html only gets dates without timestamps, but we could alternatively use the go proxy too:
      #   1) Fetch the list of versions: https://proxy.golang.org/#{module_name}/@v/list
      #   2) And for each version, fetch https://proxy.golang.org/#{module_name}/@v/#{v}.info

      versions = get_raw("#{PROXY_BASE_URL}/#{encode_for_proxy(raw_project[:name])}/@v/list")
        &.lines
        &.map(&:strip)
        &.reject(&:blank?)

      project_latest_version_number = latest_version_number(raw_project[:name])
      versions = [project_latest_version_number] if versions.blank? && project_latest_version_number

      go_mod = fetch_mod(raw_project[:name])
      versions.map do |v|
        next if go_mod&.retracted?(v)

        known = known_versions[v]

        if known && known[:original_license].present?
          VersionBuilder.build_hash(
            number: known[:number],
            created_at: known[:created_at], # TODO: do we need created_at?
            published_at: known[:published_at],
            original_license: known[:original_license]
          )
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

        # if this is a verified module name then no need to lookup anything
        is_module = module?(raw_project[:name], raw_project: raw_project)
        versioned_module_regex = raw_project[:name].match(VERSION_MODULE_REGEX)

        unless is_module
          # if this is a versioned module, make sure to find the right versioned project
          if versioned_module_regex
            # try and find a versioned name matching this repository_url
            existing_project_name = Project
              .where(platform: "Go")
              .where(
                "lower(repository_url) = :repo_url and name like :name",
                repo_url: url.downcase,
                name: "%/#{versioned_module_regex[2]}"
              )
              .first
                                      &.name

            # if we didn't find one then try and get the base project
            unless existing_project_name.present? # rubocop: disable Metrics/BlockNesting
              versioned_name = Project.where(platform: "Go").where("lower(repository_url) = ? and name not like '%/v'", url.downcase).first&.name
              existing_project_name = versioned_name&.concat("/#{versioned_module_regex[2]}")
            end
          else
            # we cannot always be sure that the incoming name is the canonical name if we are receiving a non module name
            # so to reduce generating multiple projects for the same name see if there is a case insensitive
            # match already for this name
            existing_project_name = Project.where(platform: "Go").lower_name(raw_project[:name].downcase).first&.name
          end
        end

        MappingBuilder.build_hash(
          name: existing_project_name.presence || raw_project[:name],
          description: raw_project[:html].css(".Documentation-overview p").map(&:text).join("\n").strip,
          licenses: raw_project[:html].css('*[data-test-id="UnitHeader-license"]').map(&:text).join(","),
          repository_url: url,
          homepage: url
        )
      else
        { name: raw_project[:name] }
      end
    end

    def self.dependencies(name, version, _mapped_project)
      fetch_mod(name, version: version)&.dependencies || []
    end

    def self.get_repository_url(project)
      request("https://#{project['Package']}").to_hash[:url].to_s
    end

    # checks to see if a page exists for the name on pkg.go.dev
    def self.valid_project?(name)
      response = request("#{DISCOVER_URL}/#{name}")
      response.status == 200
    end

    # Check to see if this project name has a valid go.mod file according to the information on pkg.go.dev
    # optional parameter raw_project can be passed in to skip the HTTP call to pkg.go.dev, the object structure
    # should match the one returned from the project() method
    def self.module?(name, raw_project: nil)
      raw_project = raw_project.presence || project(name)

      return false unless raw_project.present?

      # The "module" pill icon at the top.
      is_a_module = page_types(raw_project: raw_project).include?("module")

      # The "Valid go.mod file" section at the top.
      has_valid_go_mod = raw_project[:html].css(".UnitMeta-details > li details summary img")&.first&.attribute("alt")&.value == "checked"

      # NOTE: these combinations can exist on pkg.go.dev, so we must check that it is both a "module" and has a valid go.mod.
      #   * "modules" with valid go.mod: https://pkg.go.dev/github.com/robfig/cron/v3 (INGEST)
      #   * "modules" with invalid go.mod: https://pkg.go.dev/github.com/robfig/cron (IGNORE)
      #   * "packages"/etc with valid go.mod: https://pkg.go.dev/k8s.io/kubernetes/pkg/kubelet/qos (IGNORE)
      #   * "packages"/etc with invalid go.mod: https://pkg.go.dev/github.com/cloudfoundry/noaa/errors (IGNORE)

      is_a_module && has_valid_go_mod
    end

    # looks at the module declaration for the latest version's go.mod file and returns that if found
    # if nothing is found, nil is returned
    def self.name_in_go_mod(name)
      fetch_mod(name)&.canonical_module_name
    end

    # will convert a string with capital letters and replace with a "!" prepended to the lowercase letter
    # this is needed to follow the goproxy protocol and find versions correctly for modules with capital letters in them
    # https://go.dev/ref/mod#goproxy-protocol
    def self.encode_for_proxy(str)
      str.gsub(/[A-Z]/) { |s| "!#{s.downcase}" }
    end

    # Returns the types listed at the top of pkg.go.dev pages. Known values are: module, package, directory, command.
    private_class_method def self.page_types(raw_project:)
      raw_project[:html].css(".go-Main-headerTitle .go-Chip").map(&:text).map(&:strip)
    end

    private_class_method def self.latest_version_number(name)
      json = get_json("#{PROXY_BASE_URL}/#{encode_for_proxy(name)}/@latest")
      number = json&.dig("Version")

      Rails.logger.info "[Unable to fetch latest version number] name=#{name}" if number.blank?

      number
    end

    private_class_method def self.fetch_mod(name, version: nil)
      # Go proxy spec: https://golang.org/cmd/go/#hdr-Module_proxy_protocol
      # TODO: this can take up to 2sec if it's a cache miss on the proxy. Might be able
      # to scrape the webpage or wait for an API for a faster fetch here.

      version = latest_version_number(name) if version.nil?
      return if version.nil?

      mod_contents = get_raw("#{PROXY_BASE_URL}/#{encode_for_proxy(name)}/@v/#{encode_for_proxy(version)}.mod")

      if mod_contents.blank?
        Rails.logger.info "[Unable to fetch go.mod contents] name=#{name}"
        return
      end

      GoMod.new(mod_contents)
    end
  end
end
