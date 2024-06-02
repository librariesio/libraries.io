# frozen_string_literal: true

module PackageManager
  class Packagist < MultipleSourcesBase
    REPOSITORY_SOURCE_NAME = "Main"
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://packagist.org"
    COLOR = "#4F5D95"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    # TODO: rename PackageManager::Packagist -> PackageManager::Composer, and then  PackageManager::Packagist::Main => PackageManager::Composer::Packagist
    PROVIDER_MAP = ProviderMap.new(prioritized_provider_infos: [
      ProviderInfo.new(identifier: "Main", default: true, provider_class: Main),
      ProviderInfo.new(identifier: "Packagist", provider_class: Main),
      ProviderInfo.new(identifier: "Drupal", provider_class: Drupal),
    ])

    def self.formatted_name
      "Packagist"
    end

    def self.db_platform
      "Packagist"
    end

    def self.download_url(_db_project, _version = nil)
      nil
    end

    def self.check_status_url(db_project)
      package_link(db_project)
    end

    def self.repository_base
      nil
    end

    def self.project_names
      get("https://packagist.org/packages/list.json")["packageNames"]
    end

    def self.recent_names
      u = "https://packagist.org/feeds/releases.rss"
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = "https://packagist.org/feeds/packages.rss"
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split.first } + new_packages).uniq
    end

    def self.project(name)
      # The main v2 endpoint only returns a list of versions (no single source-of-truth for the project)
      # and excludes dev versions, so if that list of versions is empty, fallback to the dev list of versions.
      get("https://repo.packagist.org/p2/#{name}.json")&.dig("packages", name).presence ||
        get("https://repo.packagist.org/p2/#{name}~dev.json")&.dig("packages", name)
    end

    def self.deprecation_info(db_project)
      is_deprecated = project(db_project.name)&.first&.dig("abandoned") || ""

      {
        is_deprecated: is_deprecated != "",
        message: is_deprecated.is_a?(String) && is_deprecated.present? ? "Replacement: #{is_deprecated}" : "",
      }
    end

    def self.mapping(raw_project)
      return nil unless raw_project.any?

      # In V2 API, it looks like the first version is the one with all the metadata (name, etc)
      # (This might not necessarily be the version with the highest "time" value)
      latest_version = raw_project.first

      return if latest_version.nil?

      MappingBuilder.build_hash(
        name: latest_version["name"],
        description: latest_version["description"],
        homepage: latest_version["homepage"],
        keywords_array: Array.wrap(latest_version["keywords"]),
        licenses: latest_version["license"]&.join(","),
        repository_url: repo_fallback(latest_version["source"]&.fetch("url"), latest_version["homepage"]),
        versions: raw_project # packagist has the list of versions as raw_project and this then lets us pull dependencies in self.dependencies
      )
    end

    def self.versions(raw_project, _name)
      acceptable_versions(raw_project).map do |version|
        {
          number: version["version"],
          published_at: version["time"],
          original_license: version["license"],
        }
      end
    end

    def self.acceptable_versions(versions)
      versions.select do |k, _v|
        # See: https://getcomposer.org/doc/articles/versions.md#branches
        (k =~ /^dev-.*/i).nil? && (k =~ /\.x-dev$/i).nil?
      end
    end

    def self.dependencies(_name, version, mapped_project)
      vers = mapped_project[:versions].find { |v| v["version"] == version }
      return [] if vers.nil?

      map_dependencies(vers.fetch("require", {}).except("php"), "runtime") +
        map_dependencies(vers.fetch("require-dev", {}).except("php"), "Development")
    end
  end
end
