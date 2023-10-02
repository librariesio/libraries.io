# frozen_string_literal: true

require "zip"

module PackageManager
  class NuGet < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://www.nuget.org"
    COLOR = "#178600"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.package_link(db_project, version = nil)
      "https://www.nuget.org/packages/#{db_project.name}/#{version}"
    end

    def self.download_url_by_name(name, version = nil)
      "https://www.nuget.org/api/v2/package/#{name}/#{version}"
    end

    def self.download_url(db_project, version = nil)
      download_url_by_name(db_project.name, version)
    end

    def self.install_instructions(db_project, version = nil)
      "Install-Package #{db_project.name}" + (version ? " -Version #{version}" : "")
    end

    def self.deprecation_info(db_project)
      releases = get_releases(db_project.name)

      deprecation = releases.last&.deprecation

      if deprecation.present?
        {
          is_deprecated: true,
          message: deprecation.message,
          alternate_package: deprecation.alternate_package,
        }
      else
        {
          is_deprecated: false,
          message: "",
          alternate_package: nil,
        }
      end
    end

    def self.load_names(limit = nil)
      endpoints = name_endpoints
      segment_count = limit || (endpoints.length - 1)

      endpoints.reverse[0..segment_count].each do |endpoint|
        package_ids = get_names(endpoint)
        package_ids.each { |id| REDIS.sadd "nuget-names", id }
      end
    end

    def self.recent_names
      name_endpoints.reverse[0..2].map { |url| get_names(url) }.flatten.uniq
    end

    def self.name_endpoints
      get("https://api.nuget.org/v3/catalog0/index.json")["items"].map { |i| i["@id"] }
    end

    def self.get_names(endpoint)
      get(endpoint)["items"].map { |i| i["nuget:id"] }
    end

    def self.project_names
      REDIS.smembers "nuget-names"
    end

    def self.project(name)
      canonical_name = fetch_canonical_nuget_name(name)

      if name != canonical_name
        StructuredLog.capture("CANONICAL_NAME_DIFFERS", { platform: "nuget", name: name, canonical_name: canonical_name })
        name = canonical_name if canonical_name
      end

      h = {
        name: name,
      }
      h[:releases] = get_releases(name)
      h[:versions] = versions(h, name)
      return {} unless h[:versions].any?

      h
    end

    def self.package_file(name, version)
      url = download_url_by_name(name, version)
      StringIO.new(get_raw(url))
    end

    def self.nuspec(name, version)
      nuspec = nil

      Zip::File.open_buffer(package_file(name, version)) do |zip|
        zip.each do |file|
          # the correct nuspec file will be at the root of the tree with the package name in the filename
          # package identifiers are case-insensitive: https://learn.microsoft.com/en-us/nuget/reference/nuspec#id
          file.get_input_stream { |io| nuspec = Ox.parse(io.read) } if file.name.downcase["#{name}.nuspec".downcase]
        end
      end

      unless nuspec
        Rails.logger.error(
          "Malformed NuGet package file: NuGet/#{name}: No matching nuspec file found"
        )
      end

      nuspec
    rescue Zip::Error, Ox::ParseError => e
      Rails.logger.error(
        "Unable to process NuGet package file: NuGet/#{name}: #{e.message}"
      )
      nil
    end

    def self.get_releases(name)
      SemverRegistrationApiProjectReleasesBuilder.build(project_name: name).releases
    rescue StandardError => e
      Rails.logger.error("Unable to retrieve releases for NuGet project #{name}: #{e.message}")

      []
    end

    def self.mapping(raw_project)
      item = raw_project[:releases].last
      raw_nuspec = nuspec(raw_project[:name], item.version_number)
      nuspec_repo = raw_nuspec&.locate("package/metadata/repository")&.first
      nuspec_repo = nuspec_repo["url"] if nuspec_repo

      {
        name: raw_project[:name],
        description: item.description,
        homepage: item.project_url,
        keywords_array: item.tags,
        repository_url: repo_fallback(nuspec_repo, item.project_url),
        releases: raw_project[:releases],
        licenses: item.licenses,
      }
    end

    def self.versions(raw_project, _name)
      raw_project[:releases].map do |item|
        {
          number: item.version_number,
          published_at: item.published_at,
          original_license: item.original_license,
        }
      end
    end

    def self.dependencies(_name, version, mapped_project)
      current_version = mapped_project[:releases].find { |v| v.version_number == version }

      current_version.dependencies.map do |dep|
        {
          project_name: dep.name,
          requirements: dep.requirements,
          kind: "runtime",
          optional: false,
          platform: name.demodulize,
        }
      end
    end

    class ParseCanonicalNameFailedError < StandardError; end

    # Returns canonical casing for case-insensitive NuGet package names
    # @param name [String] A given project name to check
    # @return [String] If successfully found, the canonical form of the given name
    # @return [nil] The scrape request was unsuccessful
    # @return [false] The scrape succeeded, but we didn't detect a name
    def self.fetch_canonical_nuget_name(name)
      base_url = "https://nuget.org/packages/"
      page = get_html("#{base_url}#{name}")
      og_url_element = page.css("meta[property='og:url']").first

      if page.text.empty? # Request failed, likely temporarily
        StructuredLog.capture("FETCH_CANONICAL_NAME_FAILED", { platform: "nuget", name: name })
        return nil
      elsif og_url_element.nil?
        # If we got a response, but don't find this element, it most likely means
        # the project was removed upstream.
        StructuredLog.capture("CANONICAL_NAME_ELEMENT_MISSING", { platform: "nuget", name: name })
        return false
      end

      og_url = og_url_element.attributes["content"]&.text || ""
      canonical_name = og_url.sub(base_url, "").sub(/\/$/, "")

      # If we got as far as to grab values but they don't meet our assumptions, this should be
      # exceptional. It likely means we need to update this method.
      if !og_url.start_with?(base_url) || canonical_name.blank?
        raise ParseCanonicalNameFailedError, "Could not parse a canonical name for `#{name}`. Did upstream change their markup structure?"
      end

      canonical_name
    end
  end
end
