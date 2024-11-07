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

      # we want to get all the versions for a given pod from the text file
      pod_info = get_raw(pod_versions_url(name))
        .force_encoding("UTF-8")
        .split("\n")
        .find { |line| line.starts_with?("#{name}/") }
      return {} unless pod_info.present? # it's been removed

      pod_versions = pod_info.split("/")[1..]

      latest_version = pod_versions.max_by { |version| version.split(".").map(&:to_i) }
      # then we have to get the information for each version. cdn has the podspec but we have to go to the
      # git commit history to get a published_at date
      versions = pod_versions.to_h do |v|
        commit_info = AuthToken.client.commits("CocoaPods/Specs", path: podspec_path(name, v), page: 1, per_page: 1)
        pod_json = get_json("https://cdn.cocoapods.org/#{podspec_path(name, v)}")
        pod_json["published_at"] = commit_info[0]&.to_h&.dig(:commit, :committer, :date)
        [v, pod_json]
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
      raw_project.fetch("versions", {}).map do |(k, v)|
        VersionBuilder.build_hash(number: k.to_s,
                                  # TODO: we could capture deprecated_in_favor_of and use it
                                  status: v["deprecated"] || v["deprecated_in_favor_of"].present? ? "Deprecated" : VersionBuilder::MISSING,
                                  published_at: v["published_at"] || VersionBuilder::MISSING,
                                  original_license: parse_license(v["license"]) || VersionBuilder::MISSING)
      end
    end

    def self.parse_license(project_license)
      project_license.is_a?(Hash) ? project_license["type"] : project_license
    end

    def self.cdn_shard(name)
      # the cocoapods shard is based on the first 3 digits of the md5 of the name of the project
      Digest::MD5.hexdigest(name)[0..2].chars
    end

    def self.pod_versions_url(name)
      "https://cdn.cocoapods.org/all_pods_versions_#{cdn_shard(name).join('_')}.txt"
    end

    def self.podspec_path(name, version)
      "Specs/#{cdn_shard(name).join('/')}/#{CGI.escape(name)}/#{version}/#{CGI.escape(name)}.podspec.json"
    end
  end
end
