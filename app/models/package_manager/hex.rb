# frozen_string_literal: true

module PackageManager
  class Hex < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://hex.pm"
    COLOR = "#6e4a7e"

    def self.package_link(project, version = nil)
      "https://hex.pm/packages/#{project.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
    end

    def self.documentation_url(name, version = nil)
      "http://hexdocs.pm/#{name}/#{version}"
    end

    def self.project_names
      page = 1
      projects = []
      while page < 1000
        r = get("https://hex.pm/api/packages?page=#{page}")
        break if r == []

        projects += r
        page += 1
      end
      projects.map { |project| project["name"] }
    end

    def self.recent_names
      (get("https://hex.pm/api/packages?sort=inserted_at").map { |project| project["name"] } +
      get("https://hex.pm/api/packages?sort=updated_at").map { |project| project["name"] }).uniq
    end

    def self.project(name)
      sleep 30
      get("https://hex.pm/api/packages/#{name}")
    end

    def self.mapping(project)
      links = project["meta"].fetch("links", {}).each_with_object({}) do |(k, v), h|
        h[k.downcase] = v
      end
      {
        name: project["name"],
        homepage: links.except("github").first.try(:last),
        repository_url: links["github"],
        description: project["meta"]["description"],
        licenses: repo_fallback(project["meta"].fetch("licenses", []).join(","), links.except("github").first.try(:last)),
      }
    end

    def self.versions(project, _name)
      project["releases"].map do |version|
        {
          number: version["version"],
          published_at: version["inserted_at"],
        }
      end
    end

    def self.dependencies(name, version, _mapped_project)
      deps = get("https://hex.pm/api/packages/#{name}/releases/#{version}")["requirements"]
      return [] if deps.nil?

      deps.map do |k, v|
        {
          project_name: k,
          requirements: v["requirement"],
          kind: "runtime",
          optional: v["optional"],
          platform: self.name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://hex.pm/api/packages/#{name}")
      json["owners"].map do |user|
        {
          uuid: "hex-" + user["username"],
          email: user["email"],
          login: user["username"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://hex.pm/users/#{login}"
    end
  end
end
