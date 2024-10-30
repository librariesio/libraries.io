# frozen_string_literal: true

module PackageManager
  class CocoaPods < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://cocoapods.org/"
    COLOR = "#438eff"

    def self.package_link(db_project, _version = nil)
      "https://cocoapods.org/pods/#{db_project.name}"
    end

    def self.documentation_url(name, version = nil)
      "https://cocoadocs.org/docsets/#{name}/#{version}"
    end

    def self.install_instructions(db_project, _version = nil)
      "pod try #{db_project.name}"
    end

    def self.project_names
      get_raw("https://cdn.cocoapods.org/all_pods.txt").split("\n")
    end

    def self.recent_names
      # changes to cocoapods show up in their commit feed
      u = "https://github.com/CocoaPods/Specs/commits.atom"
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split[1] }.uniq
    end

    def self.project(name)
      # cocoapods has a CDN version of the podspecs that can be retrieved
      # based on the details in https://blog.cocoapods.org/CocoaPods-1.7.2/
      # so let's use that as the basis of how we pull information about a given
      # project

      # the cocoapods shard is based on the first 3 digits of the md5 of the name of the project
      shard = Digest::MD5.hexdigest(name)[0..2].chars

      # we want to get all the versions for a given pod from the text file
      pod_versions = get_raw("https://cdn.cocoapods.org/all_pods_versions_#{shard.join('_')}.txt")
        .split("\n")
        .find { |line| line.starts_with?("#{name}/") }
        .split("/")[1..]

      latest_version = pod_versions.max_by { |version| version.split(".").map(&:to_i) }
      # then we have to get the information for each version
      versions = pod_versions.to_h do |v|
        [v, get_json("https://cdn.cocoapods.org/Specs/#{shard.join('/')}/#{name}/#{v}/#{name}.podspec.json")]
      end

      # and finally, merge the latest version info to the top-level
      versions.fetch(latest_version, {}).then do |v|
        v.merge("versions" => versions) if versions.present?
      end
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: raw_project["summary"],
        homepage: raw_project["homepage"],
        licenses: parse_license(raw_project["license"]),
        repository_url: repo_fallback(raw_project.dig("source", "git"), "")
      )
    end

    def self.versions(raw_project, _name)
      raw_project.fetch("versions", {}).keys.map do |v|
        VersionBuilder.build_hash(number: v.to_s)
      end
    end

    def self.parse_license(project_license)
      project_license.is_a?(Hash) ? project_license["type"] : project_license
    end
  end
end
