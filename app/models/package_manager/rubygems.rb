# frozen_string_literal: true

module PackageManager
  class Rubygems < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://rubygems.org"
    COLOR = "#701516"

    def self.package_link(project, version = nil)
      "https://rubygems.org/gems/#{project.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.download_url(db_project, version = nil)
      "https://rubygems.org/downloads/#{db_project.name}-#{version}.gem"
    end

    def self.documentation_url(name, version = nil)
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    end

    def self.install_instructions(project, version = nil)
      "gem install #{project.name}" + (version ? " -v #{version}" : "")
    end

    def self.check_status_url(project)
      "https://rubygems.org/api/v1/versions/#{project.name}.json"
    end

    def self.project_names
      gems = Marshal.safe_load(Gem.gunzip(get_raw("http://production.cf.rubygems.org/specs.4.8.gz")))
      gems.map(&:first).uniq
    end

    def self.recent_names
      updated = get("https://rubygems.org/api/v1/activity/just_updated.json").map { |h| h["name"] }
      new_gems = get("https://rubygems.org/api/v1/activity/latest.json").map { |h| h["name"] }
      (updated + new_gems).uniq
    end

    def self.project(name)
      get_json("https://rubygems.org/api/v1/gems/#{name}.json")
    rescue StandardError
      {}
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        description: raw_project["info"],
        homepage: raw_project["homepage_uri"],
        licenses: raw_project.fetch("licenses", []).try(:join, ","),
        repository_url: repo_fallback(raw_project["source_code_uri"], raw_project["homepage_uri"]),
      }
    end

    def self.versions(raw_project, _name)
      json = get_json("https://rubygems.org/api/v1/versions/#{raw_project['name']}.json")
      json.map do |v|
        license = v.fetch("licenses", "")
        license = "" if license.nil?
        {
          number: v["number"],
          published_at: v["created_at"],
          original_license: license,
        }
      end
    rescue StandardError
      []
    end

    def self.dependencies(name, version, _mapped_project)
      json = get_json("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")

      deps = json["dependencies"]
      map_dependencies(deps["development"], "Development") + map_dependencies(deps["runtime"], "runtime")
    rescue StandardError
      []
    end

    def self.map_dependencies(deps, kind)
      deps.map do |dep|
        {
          project_name: dep["name"],
          requirements: dep["requirements"],
          kind: kind,
          platform: name.demodulize,
        }
      end
    end

    def self.download_registry_users(name)
      json = get_json("https://rubygems.org/api/v1/gems/#{name}/owners.json")
      json.map do |user|
        {
          uuid: user["id"],
          email: user["email"],
          login: user["handle"],
        }
      end
    rescue StandardError
      []
    end

    def self.registry_user_url(login)
      "https://rubygems.org/profiles/#{login}"
    end
  end
end
