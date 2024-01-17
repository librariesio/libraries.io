# frozen_string_literal: true

module PackageManager
  class Go < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
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

    VERSION_MODULE_REGEX = /(.+)\/(v\d+)(\/|$)/.freeze

    class UnknownGoType < StandardError; end

    def self.missing_version_remover
      PackageManager::Base::MissingVersionRemover
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
      data = {
        number: version_string,
        published_at: published_at,
      }

      # Supplement with license info from pkg.go.dev
      doc_html = get_html("#{DISCOVER_URL}/#{raw_project[:name]}")
      data[:original_license] = doc_html.css('*[data-test-id="UnitHeader-license"]').map(&:text).join(",")

      data
    end

    # rubocop: disable Lint/UnusedMethodArgument
    def self.update(name, sync_version: :all, force_sync_dependencies: false)
      project = super(name, sync_version: sync_version)

      # if Base.update returns something false-y, pass that along
      return project unless project

      # call update on base module name if the name is appended with major version
      # example: github.com/myexample/modulename/v2
      # use the returned project name in case it finds a Project via repository_url

      # pick one version to use for the base module update so that we don't sync every version
      # when reusing the PackageManagerDownloadWorker to initialize the base name Project
      base_sync_version = sync_version unless sync_version == :all
      base_sync_version = base_sync_version.presence || project.versions.first&.number&.presence
      update_base_module(project.name, base_sync_version) if project.present? && project.name.match?(VERSION_MODULE_REGEX)

      project
    end
    # rubocop: enable Lint/UnusedMethodArgument

    def self.update_base_module(name, base_sync_version)
      matches = name.match(VERSION_MODULE_REGEX)

      unless Project.where(platform: "Go", name: matches[1]).exists?
        # run this inline to generate the base module Project if it doesn't already exist
        PackageManagerDownloadWorker.new.perform(self.name, matches[1], base_sync_version)
      end

      module_project = Project.find_by(platform: "Go", name: name)
      base_module_project = Project.find_by(platform: "Go", name: matches[1])
      return if module_project.nil? || base_module_project.nil?

      # find any versions the /vx module knows about that the base module doesn't have already
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
      return nil if doc_html.text.blank?

      raw_project = { name: name, html: doc_html, overview_html: doc_html }

      # pages on pkg.go.dev can be listed as 'package', 'module', or both. We only scrape Go Modules.
      unless is_a_module?(raw_project: raw_project)
        if !is_a_project?(raw_project: raw_project) && !is_a_command?(raw_project: raw_project)
          # this is more for our record-keeping so we know what possible types there are.
          Bugsnag.notify(UnknownGoType.new("Unknown Go project type (it is neither a package, a command or a module) for #{name}: #{page_type}")) if defined?(Bugsnag)
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

        # if this is a verified module name then no need to lookup anything
        is_module = module?(raw_project[:name], raw_project: raw_project)
        versioned_module_regex = raw_project[:name].match(VERSION_MODULE_REGEX)
        unless is_module
          # if this is a versioned module, make sure to find the right versioned project
          if versioned_module_regex
            # try and find a versioned name matching this repository_url
            existing_project_name = Project.where(platform: "Go").where("lower(repository_url) = :repo_url and name like :name", repo_url: url.downcase, name: "%/#{versioned_module_regex[2]}").first&.name

            # if we didn't find one then try and get the base project
            unless existing_project_name.present? # rubocop: disable Metrics/BlockNesting
              versioned_name = Project.where(platform: "Go").where("lower(repository_url) = ? and name not like '%/v'", url.downcase).first&.name
              existing_project_name = versioned_name&.concat("/#{versioned_module_regex[2]}")
            end
          else
            existing_project_name = Project.where(platform: "Go").where("lower(name) = ?", raw_project[:name].downcase).first&.name
          end
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
      fetch_mod(name, version: version)&.dependencies || []
    end

    # https://golang.org/cmd/go/#hdr-Import_path_syntax
    def self.project_find_names(name)
      return [name] if name.start_with?(*KNOWN_HOSTS)
      return [name] if KNOWN_VCS.any?(&name.method(:include?))

      host = name.split("/").first
      return [name] if Rails.cache.exist?("unreachable-go-hosts:#{host}")

      begin
        # https://go.dev/ref/mod#serving-from-proxy
        go_import = get_html("https://#{name}?go-get=1", { request: { timeout: 2 } })
          .xpath('//meta[@name="go-import"]')
          .first
          &.attribute("content")
          &.value
          &.split(" ")
          &.last
          &.sub(/https?:\/\//, "")

        go_import&.start_with?(*KNOWN_HOSTS) ? [go_import] : [name]
      rescue Faraday::ConnectionFailed => e
        # We can get here from go modules that don't exist anymore, or having server troubles:
        # Fallback to the given name, cache the host as "bad" for a day,
        # log it (to analyze later) and notify us to be safe.
        Rails.logger.info "[Caching unreachable go host] name=#{name}"
        Rails.cache.write("unreachable-go-hosts:#{host}", true, ex: 1.day)
        Bugsnag.notify(e)
        [name]
      rescue StandardError
        [name]
      end
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
      is_a_module = is_a_module?(raw_project: raw_project)

      # The "Valid go.mod file" section at the top.
      has_valid_go_mod = raw_project[:html].css(".UnitMeta-details > li details summary img")&.first&.attribute("alt")&.value == "checked"

      # Note about why these are two different checks and they're both needed here. There exist:
      # * "packages" with valid go.mod: https://pkg.go.dev/k8s.io/kubernetes/pkg/kubelet/qos
      # * "packages" with invalid go.mod: https://pkg.go.dev/github.com/cloudfoundry/noaa/errors
      # * "modules" with valid go.mod: https://pkg.go.dev/github.com/robfig/cron/v3
      # * "modules" with invalid go.mod: https://pkg.go.dev/github.com/robfig/cron
      is_a_module && has_valid_go_mod
    end

    # Check if this is a Go Module.
    def self.is_a_module?(raw_project: nil)
      raw_project[:html].css(".go-Main-headerTitle .go-Chip").text.include?("module")
    end

    # Check if this is a Go Package.
    def self.is_a_project?(raw_project: nil)
      raw_project[:html].css(".go-Main-headerTitle .go-Chip").text.include?("package")
    end

    # Check if this is a Go Command. (e.g. https://pkg.go.dev/github.com/mre-fog/etcd2)
    def self.is_a_command?(raw_project: nil)
      raw_project[:html].css(".go-Main-headerTitle .go-Chip").text.include?("command")
    end

    # looks at the module declaration for the latest version's go.mod file and returns that if found
    # if nothing is found, nil is returned
    def self.canonical_module_name(name)
      fetch_mod(name)&.canonical_module_name
    end

    # will convert a string with capital letters and replace with a "!" prepended to the lowercase letter
    # this is needed to follow the goproxy protocol and find versions correctly for modules with capital letters in them
    # https://go.dev/ref/mod#goproxy-protocol
    def self.encode_for_proxy(str)
      str.gsub(/[A-Z]/) { |s| "!#{s.downcase}" }
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
