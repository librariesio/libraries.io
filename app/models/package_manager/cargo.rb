# frozen_string_literal: true

require "rubygems/package"

module PackageManager
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://crates.io"
    COLOR = "#dea584"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.package_link(db_project, version = nil)
      "https://crates.io/crates/#{db_project.name}/#{version}"
    end

    def self.download_url(db_project, version = nil)
      "https://crates.io/api/v1/crates/#{db_project.name}/#{version}/download"
    end

    def self.documentation_url(name, version = nil)
      "https://docs.rs/#{name}/#{version}"
    end

    def self.check_status_url(db_project)
      "https://crates.io/api/v1/crates/#{db_project.name}"
    end

    def self.deprecation_info(db_project)
      raw_project = project(db_project.name)
      keywords = Array.wrap(raw_project["crate"]["keywords"])

      if keywords.map(&:downcase).include?("deprecated")
        return {
          is_deprecated: true,
          message: "Marked as deprecated in project keywords",
        }
      end

      version = raw_project.dig("crate", "newest_version")
      url = download_url(db_project, version)
      body = get_raw(url)
      if body.empty? # if we can't fetch it, we can't say if it is deprecated or not but default false
        return {
          is_deprecated: false,
          message: nil,
        }
      end

      tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(body)))
      tar_extract.rewind
      toml = tar_extract.find { |entry| entry.full_name.end_with?("/Cargo.toml") }.read
      cargo_toml = Tomlrb.parse(toml)
      status = cargo_toml.dig("badges", "maintenance", "status")
      is_deprecated = status == "deprecated"
      {
        is_deprecated: is_deprecated,
        message: is_deprecated ? "Marked as deprecated in Cargo.toml" : nil,
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

    def self.mapping(raw_project)
      latest_version = versions(raw_project, nil).to_a.first
      {
        name: raw_project["crate"]["id"],
        homepage: raw_project["crate"]["homepage"],
        description: raw_project["crate"]["description"],
        keywords_array: Array.wrap(raw_project["crate"]["keywords"]),
        licenses: latest_version&.fetch(:original_license),
        repository_url: repo_fallback(raw_project["crate"]["repository"], raw_project["crate"]["homepage"]),
      }
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |version|
        VersionBuilder.build_hash(
          number: version["num"],
          published_at: version["created_at"],
          original_license: version["license"]
        )
      end
    end

    def self.dependencies(name, version, _mapped_project)
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
