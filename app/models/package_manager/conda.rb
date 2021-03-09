# frozen_string_literal: true

module PackageManager
  class Conda < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://anaconda.org"
    API_URL = "https://conda.libraries.io"

    def self.formatted_name
      "conda"
    end

    def self.project_names
      get_json("#{API_URL}/packages").keys
    end

    def self.all_projects
      get_json("#{API_URL}/packages")
    end

    def self.recent_names
      last_update = Version.where(project: Project.where(platform: "Conda")).select(:updated_at).order(updated_at: :desc).limit(1).first&.updated_at
      packages = get_json("#{API_URL}/packages")

      return packages.keys if last_update.nil?

      packages.keys.filter do |name|
        packages[name]["versions"].any? { |version| version["published_at"].is_a?(String) && Time.parse(version["published_at"]) > last_update }
      end
    end

    def self.package_link(project, _version = nil)
      "https://anaconda.org/anaconda/#{project.name}"
    end

    def self.install_instructions(project, _version = nil)
      "conda install -c anaconda #{project.name}"
    end

    def self.project(name)
      get_json("#{API_URL}/package/#{name}")
    end

    def self.check_status_url(project)
      "#{API_URL}/package/#{project.name}"
    end

    def self.mapping(project)
      # TODO can we make this more explicit?
      project.deep_symbolize_keys
    end

    def self.versions(project, _name)
      project["versions"].map { |version| version.deep_symbolize_keys.slice(:number, :original_license, :published_at) }
    end

    def self.dependencies(name, version, _mapped_project)
      version_data = get_json("#{API_URL}/package/#{name}")["versions"]
      deps = version_data.find { |item| item["number"] == version }&.dig("dependencies")&.map { |d| d.split(" ") }
      map_dependencies(deps, "runtime")
    end
  end
end
