# frozen_string_literal: true

module PackageManager
  class Packagist < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://packagist.org"
    COLOR = "#4F5D95"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.package_link(project, version = nil)
      "https://packagist.org/packages/#{project.name}##{version}"
    end

    def self.project_names
      get("https://packagist.org/packages/list.json")["packageNames"]
    end

    def self.recent_names
      u = "https://packagist.org/feeds/releases.rss"
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = "https://packagist.org/feeds/packages.rss"
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split(" ").first } + new_packages).uniq
    end

    def self.project(name)
      get("https://packagist.org/packages/#{name}.json")
        &.fetch("package")
    end

    def self.deprecation_info(name)
      is_deprecated = project(name).dig("abandoned") || ""

      {
        is_deprecated: is_deprecated != "",
        message: is_deprecated.is_a?(String) && is_deprecated.present? ? "Replacement: #{is_deprecated}" : "",
      }
    end

    def self.mapping(raw_project)
      return nil unless raw_project["versions"].any?

      # for version comparison of php, we want to reject any dev versions unless
      # there are only dev versions of the project
      versions = raw_project["versions"].values.reject { |v| v["version"].include? "dev" }
      versions = raw_project["versions"].values if versions.empty?
      # then we'll use the most recently published as our most recent version
      latest_version = versions.max_by { |v| v["time"] }
      {
        name: latest_version["name"],
        description: latest_version["description"],
        homepage: latest_version["home_page"],
        keywords_array: Array.wrap(latest_version["keywords"]),
        licenses: latest_version["license"].join(","),
        repository_url: repo_fallback(raw_project["repository"], latest_version["home_page"]),
      }
    end

    def self.versions(_raw_project, name)
      # TODO: Use composer v2 and unminify data https://packagist.org/apidoc
      versions = get("https://repo.packagist.org/p/#{name}.json")&.dig("packages", name) || []

      acceptable_versions(versions).map do |number, version|
        {
          number: number,
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
      vers = mapped_project[:versions][version]
      return [] if vers.nil?

      map_dependencies(vers.fetch("require", {}).reject { |k, _v| k == "php" }, "runtime") +
        map_dependencies(vers.fetch("require-dev", {}).reject { |k, _v| k == "php" }, "Development")
    end
  end
end
