# frozen_string_literal: true

module PackageManager
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://crates.io"
    COLOR = "#dea584"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.package_link(project, version = nil)
      "https://crates.io/crates/#{project.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://crates.io/api/v1/crates/#{name}/#{version}/download"
    end

    def self.documentation_url(name, version = nil)
      "https://docs.rs/#{name}/#{version}"
    end

    def self.check_status_url(project)
      "https://crates.io/api/v1/crates/#{project.name}"
    end

    def self.deprecation_info(name)
      item = project(name)
      version = item.dig("crate", "newest_version")
      url = download_url(name, version)
      body = get_raw(url)
      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(body)))
      tar_extract.rewind
      toml = tar_extract.find { |entry| entry.full_name.end_with?("/Cargo.toml") }.read
      cargo_toml = TOML.load(toml)
      status = cargo_toml.dig("badges", "maintenance", "status")
      is_deprecated = status == "deprecated"
      {
        is_deprecated: is_deprecated,
        message: is_deprecated ? "Marked as deprecated in Cargo.toml": nil
      }
    end

    def self.project_names
      page = 1
      projects = []
      loop do
        r = get("https://crates.io/api/v1/crates?page=#{page}&per_page=100")["crates"]
        break if r == []

        projects += r
        page += 1
      end
      projects.map { |project| project["name"] }
    end

    def self.recent_names
      json = get("https://crates.io/api/v1/summary")
      updated_names = json["just_updated"].map { |c| c["name"] }
      new_names = json["new_crates"].map { |c| c["name"] }
      (updated_names + new_names).uniq
    end

    def self.project(name)
      get("https://crates.io/api/v1/crates/#{name}")
    end

    def self.mapping(project)
      latest_version = project["versions"].to_a.first
      {
        name: project["crate"]["id"],
        homepage: project["crate"]["homepage"],
        description: project["crate"]["description"],
        keywords_array: Array.wrap(project["crate"]["keywords"]),
        licenses: latest_version["license"],
        repository_url: repo_fallback(project["crate"]["repository"], project["crate"]["homepage"]),
      }
    end

    def self.versions(project, _name)
      project["versions"].map do |version|
        {
          number: version["num"],
          published_at: version["created_at"],
          original_license: version["license"],
        }
      end
    end

    def self.dependencies(name, version, _project)
      deps = get("https://crates.io/api/v1/crates/#{name}/#{version}/dependencies")["dependencies"]
      return [] if deps.nil?

      deps.map do |dep|
        {
          project_name: dep["crate_id"],
          requirements: dep["req"],
          kind: dep["kind"],
          optional: dep["optional"],
          platform: self.name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://crates.io/api/v1/crates/#{name}/owner_user")
      json["users"].map do |user|
        {
          uuid: user["id"],
          name: user["name"],
          login: user["login"],
          url: user["url"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://crates.io/users/#{login}"
    end
  end
end
