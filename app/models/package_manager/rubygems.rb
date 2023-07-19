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

    def self.package_link(db_project, version = nil)
      "https://rubygems.org/gems/#{db_project.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.download_url(db_project, version = nil)
      "https://rubygems.org/downloads/#{db_project.name}-#{version}.gem"
    end

    def self.documentation_url(name, version = nil)
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    end

    def self.install_instructions(db_project, version = nil)
      "gem install #{db_project.name}" + (version ? " -v #{version}" : "")
    end

    def self.check_status_url(db_project)
      "https://rubygems.org/api/v1/versions/#{db_project.name}.json"
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

    def self.versions(raw_project, _name, parse_html: false)
      html_versions = parse_html_yanked_versions(raw_project) if parse_html
      json_versions = parse_json_versions(raw_project)

      versions = if parse_html
                   json_versions + html_versions.flatten.compact
                 else
                   json_versions
                 end
      versions.uniq { |version| version[:number] }
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

    def self.parse_html_yanked_versions(raw_project)
      html_versions = []
      page_number = 1
      all_pages_parsed = false
      until all_pages_parsed
        html = get_html("https://rubygems.org/gems/#{raw_project['name']}/versions?page=#{page_number}")

        if html.text.include?("This gem is not currently hosted on RubyGems.org.") || html.text.empty?
          all_pages_parsed = true
          break
        end

        yanked_versions = html.xpath("//li").map do |gem_version_wrap|
          gem_details = gem_version_wrap.element_children
          gem_version = gem_details[0]&.attributes&.[]("href")&.value&.split("/")&.last
          version_date = gem_details[1]&.children&.text&.to_time&.iso8601
          is_yanked = gem_details[3]&.children&.text == "yanked"

          next unless is_yanked

          {
            number: gem_version,
            published_at: version_date,
            original_license: "",
            yanked: true,
          }
        end

        page_number += 1
        html_versions << yanked_versions
      end

      html_versions
    end

    def self.parse_json_versions(raw_project)
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
    end
  end
end
