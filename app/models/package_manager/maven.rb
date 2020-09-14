# frozen_string_literal: true

module PackageManager
  class Maven < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "http://maven.org"
    BASE_URL = "https://maven-repository.com"
    COLOR = "#b07219"
    MAX_DEPTH = 5
    LICENSE_STRINGS = {
      "http://www.apache.org/licenses/LICENSE-2.0" => "Apache-2.0",
      "http://www.eclipse.org/legal/epl-v10" => "Eclipse Public License (EPL), Version 1.0",
      "http://www.eclipse.org/org/documents/edl-v10" => "Eclipse Distribution License (EDL), Version 1.0",
    }.freeze

    def self.package_link(project, version = nil)
      MavenUrl.from_name(project.name, repository_base).search(version)
    end

    def self.download_url(name, version = nil)
      MavenUrl.from_name(name, repository_base).jar(version)
    end

    def self.check_status_url(project)
      MavenUrl.from_name(project.name).base
    end

    def self.repository_base
      "https://repo1.maven.org/maven2"
    end

    def self.load_names(limit = nil)
      names = get("https://maven.libraries.io/all")
      names.each { |name| REDIS.sadd("maven-names", name)}
    end

    def self.project_names
      REDIS.smembers("maven-names")
    end

    def self.recent_names
      get("https://maven.libraries.io")
    end

    def self.project(name)
      sections = name.split(":")
      path = sections.join("/")
      versions = versions(nil, name)
      latest_version = latest_version(versions, name)
      return {} unless latest_version.present?

      {
        name: name,
        path: path,
        group_id: sections[0],
        artifact_id: sections[1],
        versions: versions,
        latest_version: latest_version,
      }
    rescue StandardError
      {}
    end

    def self.mapping(project, depth = 0)
      version_xml = get_pom(project[:group_id], project[:artifact_id], project[:latest_version])
      mapping_from_pom_xml(version_xml, depth).merge({ name: project[:name] })
    end

    def self.mapping_from_pom_xml(version_xml, depth = 0)
      xml = if version_xml.respond_to?("project")
              version_xml.project
            else
              version_xml
            end

      parent = {
        description: nil,
        homepage: nil,
        repository_url: "",
        licenses: "",
        properties: {},
      }
      if xml.locate("parent").present? && depth < MAX_DEPTH
        group_id = extract_pom_value(xml, "parent/groupId")
        artifact_id = extract_pom_value(xml, "parent/artifactId")
        version = extract_pom_value(xml, "parent/version")
        if group_id && artifact_id && version
          parent = mapping_from_pom_xml(
            get_pom(group_id, artifact_id, version),
            depth + 1
          )
        end
      end

      # merge with parent data if available and take child values on overlap
      child = {
        description: extract_pom_value(xml, "description", parent[:properties]),
        homepage: extract_pom_value(xml, "url", parent[:properties]),
        repository_url: repo_fallback(
          extract_pom_value(xml, "scm/url", parent[:properties]),
          extract_pom_value(xml, "url", parent[:properties])
        ),
        licenses: licenses(version_xml).join(","),
        properties: parent[:properties].merge(extract_pom_properties(xml)),
      }.select { |_k, v| v.present? }

      parent.merge(child)
    end

    def self.extract_pom_value(xml, location, parent_properties = {})
      # Bibliothecary will help handle property expansion within the xml
      Bibliothecary::Parsers::Maven.extract_pom_info(xml, location, parent_properties)
    end

    def self.extract_pom_properties(xml)
      xml.locate("properties/*").each_with_object({}) do |prop_node, all|
        all[prop_node.value] = prop_node.nodes.first if prop_node.respond_to?(:nodes)
      end
    end

    def self.dependencies(name, version, project)
      pom_file = get_raw(MavenUrl.from_name(name, repository_base).pom(version))
      Bibliothecary::Parsers::Maven.parse_pom_manifest(pom_file, project[:properties]).map do |dep|
        {
          project_name: dep[:name],
          requirements: dep[:requirement],
          kind: dep[:type],
          platform: formatted_name,
        }
      end
    end

    def self.versions(_project, name)
      xml_metadata = get_raw(MavenUrl.from_name(name, repository_base).maven_metadata)
      xml_versions = Nokogiri::XML(xml_metadata).css("version").map(&:text)
      retrieve_versions(xml_versions.filter {|item| !item.ends_with?("-SNAPSHOT")}, name)
    end

    def self.retrieve_versions(versions, name)
      versions.map do |version|
        begin
          pom = get_pom(*name.split(":", 2), version)
          license_list = licenses(pom)
        rescue StandardError
          license_list = nil
        end
        {
          number: version,
          published_at: Time.parse(pom.locate("publishedAt").first.text),
          original_license: license_list,
        }
      end
    end

    def self.get_pom(group_id, artifact_id, version, seen = [])
      pom_request = request(MavenUrl.new(group_id, artifact_id, repository_base).pom(version))
      xml = Ox.parse(pom_request.body)
      published_at = pom_request.headers["Last-Modified"]
      pat = Ox::Element.new("publishedAt")
      pat << published_at
      xml << pat
      seen << [group_id, artifact_id, version]

      next_group_id = xml.locate("distributionManagement/relocation/groupId/?[0]").first || group_id
      next_artifact_id = xml.locate("distributionManagement/relocation/artifactId/?[0]").first || artifact_id
      next_version = xml.locate("distributionManagement/relocation/version/?[0]").first || version

      if seen.include?([next_group_id, next_artifact_id, next_version])
        xml

      else
        begin
          get_pom(next_group_id, next_artifact_id, next_version, seen)
        rescue Faraday::Error, Ox::Error
          xml
        end
      end
    end

    def self.licenses(xml)
      xml_licenses = xml
        .locate("*/licenses/license/name")
        .flat_map(&:nodes)
      return xml_licenses if xml_licenses.any?

      comments = xml.locate("*/^Comment")
      LICENSE_STRINGS
        .select { |string, _| comments.any? { |c| c.value.include?(string) } }
        .map(&:last)
    end

    def self.latest_version(versions, name)
      if versions.present?
        versions
          .max_by { |version| version[:published_at] }
          .dig(:number)
      else
        # TODO: this is in place to handle packages that are no longer on maven-repository.com
        # this could be removed if we switched to a package data provider that supplied full information
        Project
          .find_by(name: name, platform: formatted_class)
          &.versions
          &.max_by(&:published_at)
          &.number
      end
    end

    class MavenUrl
      def self.from_name(name, repo_base)
        new(*name.split(":", 2), repo_base)
      end

      def self.legal_name?(name)
        name.present? && name.split(":").size == 2
      end

      def initialize(group_id, artifact_id, repo_base)
        @group_id = group_id
        @artifact_id = artifact_id
        @repo_base = repo_base
      end

      def base
        "#{@repo_base}/#{group_path}/#{@artifact_id}"
      end

      def jar(version)
        "#{base}/#{version}/#{@artifact_id}-#{version}.jar"
      end

      def pom(version)
        "#{base}/#{version}/#{@artifact_id}-#{version}.pom"
      end

      def search(version = nil)
        if version
          "http://search.maven.org/#artifactdetails%7C#{@group_id}%7C#{@artifact_id}%7C#{version}%7Cjar"
        else
          "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{@group_id}%22%20AND%20a%3A%22#{@artifact_id}%22"
        end
      end

      def maven_metadata
        "#{@repo_base}/#{group_path}/#{@artifact_id}/maven-metadata.xml"
      end

      private

      def group_path
        @group_id.gsub(".", "/")
      end
    end
  end
end
