# frozen_string_literal: true

module PackageManager
  class Maven < MultipleSourcesBase
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    REPOSITORY_SOURCE_NAME = "Maven"
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "http://maven.org"
    COLOR = "#b07219"
    MAX_DEPTH = 5
    LICENSE_STRINGS = {
      "://www.apache.org/licenses/LICENSE-2.0" => "Apache-2.0",
      "://www.eclipse.org/legal/epl-v10" => "Eclipse Public License (EPL), Version 1.0",
      "://www.eclipse.org/legal/epl-2.0" => "Eclipse Public License (EPL), Version 2.0",
      "://www.eclipse.org/org/documents/edl-v10" => "Eclipse Distribution License (EDL), Version 1.0",
    }.freeze
    NAME_DELIMITER = ":"

    PROVIDER_MAP = {
      "Atlassian" => Atlassian,
      "default" => MavenCentral,
      "Hortonworks" => Hortonworks,
      "Maven" => MavenCentral,
      "SpringLibs" => SpringLibs,
      "Jboss" => Jboss,
      "JbossEa" => JbossEa,
      "Google" => Google,
    }.freeze

    class POMNotFound < StandardError
      attr_reader :url

      def initialize(url)
        @url = url
        super("Missing POM: #{@url}")
      end
    end

    def self.repository_base
      PROVIDER_MAP["default"].repository_base
    end

    def self.project_names
      # NB this is just the most recent set of incremental updates to maven central, not all releases
      get("https://maven.libraries.io/mavenCentral/recent")
    end

    def self.project(name, latest: nil)
      sections = name.split(NAME_DELIMITER)
      path = sections.join("/")

      latest = latest_version(name) unless latest.present?

      return {} unless latest.present?

      {
        name: name,
        path: path,
        group_id: sections[0],
        artifact_id: sections[1],
        latest_version: latest,
      }
    rescue StandardError
      {}
    end

    def self.mapping(raw_project, depth = 0)
      latest_version_xml = get_pom(raw_project[:group_id], raw_project[:artifact_id], raw_project[:latest_version])
      mapping_from_pom_xml(latest_version_xml, depth).merge({ name: raw_project[:name] })
    rescue POMNotFound => e
      Rails.logger.info "Missing POM: #{e.url}"
      nil
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
        group_id = extract_pom_value(xml, "parent/groupId")&.strip
        artifact_id = extract_pom_value(xml, "parent/artifactId")&.strip
        version = extract_pom_value(xml, "parent/version")&.strip
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
        homepage: extract_pom_value(xml, "url", parent[:properties])&.strip,
        repository_url: repo_fallback(
          extract_pom_value(xml, "scm/url", parent[:properties])&.strip,
          extract_pom_value(xml, "url", parent[:properties])&.strip
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
      properties = xml.locate("properties/*").each_with_object({}) do |prop_node, all|
        all[prop_node.value] = prop_node.nodes.first if prop_node.respond_to?(:nodes)
      end

      # <scm><url /></scm> can be found outside of <properties /> but we're only
      # passing <properties /> to extract_pom_info() for now, even though most
      # elements in a parent pom are inheritable (except for artifactId, name,
      # and prerequisites) (see https://maven.apache.org/pom.html#inheritance)
      # To ensure that the correct "scm.url" can be inherited from parent poms,
      # we manually set "scm.url" - if it exists in the parent pom - as a
      # property for child poms to use during interpolation.
      if properties["scm.url"].blank? && (node = xml.locate("scm/url").first) && node.respond_to?(:nodes)
        properties["scm.url"] = node.nodes.first
      end

      properties
    end

    def self.dependencies(name, version, project)
      pom_file = get_raw(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).pom(version))
      Bibliothecary::Parsers::Maven.parse_pom_manifest(pom_file, project[:properties]).map do |dep|
        {
          project_name: dep[:name],
          requirements: dep[:requirement],
          kind: dep[:type],
          optional: dep.key?(:optional) ? dep[:optional] : false,
          platform: formatted_name,
        }
      end
    end

    def self.versions(raw_project, name)
      if raw_project && raw_project[:versions]
        raw_project[:versions]
      else
        xml_metadata = maven_metadata(name)
        xml_versions = Nokogiri::XML(xml_metadata).css("version").map(&:text)
        retrieve_versions(xml_versions.filter { |item| !item.ends_with?("-SNAPSHOT") }, name)
      end
    end

    def self.one_version_for_name(version, name)
      pom = get_pom(*name.split(NAME_DELIMITER, 2), version)
      begin
        license_list = licenses(pom)
      rescue StandardError
        license_list = nil
      end

      if license_list.blank? && pom.respond_to?("project") && pom.project.locate("parent").present?
        parent_version = extract_pom_value(pom.project, "parent/version")&.strip
        Rails.logger.info("[POM has parent no license] name=#{name} parent_version=#{parent_version} child_version=#{version}")
      end

      {
        number: version,
        published_at: Time.parse(pom.locate("publishedAt").first.text),
        original_license: license_list,
      }
    end

    def self.retrieve_versions(versions, name)
      # TODO: This should also look for the parent POM and if it exists + the child POM
      # is missing license data, use the data from the parent POM
      versions
        .map do |version|
          one_version_for_name(version, name)
      rescue Ox::Error, POMNotFound
        next
        end
        .compact
    end

    def self.download_pom(group_id, artifact_id, version)
      url = MavenUrl.new(group_id, artifact_id, repository_base).pom(version)
      pom_request = request(url)
      raise POMNotFound, url if pom_request.status == 404

      xml = Ox.parse(pom_request.body)
      published_at = pom_request.headers["Last-Modified"]
      pat = Ox::Element.new("publishedAt")
      pat << published_at
      xml << pat
      xml
    end

    def self.get_pom(group_id, artifact_id, version, seen = [])
      xml = download_pom(group_id, artifact_id, version)
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

    def self.maven_metadata(name)
      get_raw(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).maven_metadata)
    end

    def self.latest_version(name)
      xml_metadata = maven_metadata(name)
      latest = Nokogiri::XML(xml_metadata)
        .css("versioning > latest, versioning > release, metadata > version")
        .map(&:text)
        .first
    end

    def self.db_platform
      "Maven"
    end

    class MavenUrl
      def self.from_name(name, repo_base, delimiter = ":")
        group_id, artifact_id = *name.split(delimiter, 2)

        # Clojars names, when missing a group id, are implied to have the same group and artifact ids.
        artifact_id = group_id if artifact_id.nil? && delimiter == PackageManager::Clojars::NAME_DELIMITER

        new(group_id, artifact_id, repo_base)
      end

      def self.legal_name?(name, delimiter = ":")
        name.present? && name.split(delimiter).size == 2
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

      # this is very specific to Maven Central
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
